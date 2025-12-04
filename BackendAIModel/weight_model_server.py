#서버용 코드

import numpy as np
import firebase_admin
from firebase_admin import credentials, firestore
from sklearn.ensemble import RandomForestRegressor
import warnings
import os
from datetime import datetime
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from contextlib import asynccontextmanager

warnings.filterwarnings('ignore')

# =========================================================
# 0. 유틸리티 함수 추가 (결측치/타입 오류 방지)
# =========================================================
def safe_float_convert(value, default_value):
    """ 값을 float으로 변환, 실패 시 기본값 반환 """
    try:
        # None이나 빈 문자열 등을 처리하기 위해 먼저 문자열로 변환 시도
        if value is None or str(value).strip() == "":
            return float(default_value)
        return float(value)
    except ValueError:
        return float(default_value)
# =========================================================
# 1. 설정 및 초기화
# =========================================================
KEY_FILE = "serviceAccountKey.json"
# 실제 VM 경로로 수정 필요
CRED_PATH = "/home/semxe123/serviceAccountKey.json"

firebase_app = None
db = None
sensitivity_model = None
current_users = []

def ensure_firebase():
    global firebase_app, db
    if db is not None: return db
    path = CRED_PATH if os.path.exists(CRED_PATH) else KEY_FILE
    if not os.path.exists(path): return None
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(path)
            firebase_app = firebase_admin.initialize_app(cred)
        else:
            firebase_app = firebase_admin.get_app()
        db = firestore.client()
        print("[Server] Firebase Connected.")
        return db
    except Exception as e:
        print(f"[Server] Firebase Connection Error: {e}")
        return None

# =========================================================
# 2. JSON 변환 유틸리티 (Random Forest -> JSON)
# =========================================================
def tree_to_json(tree, feature_names):
    tree_ = tree.tree_
    feature_name = [feature_names[i] if i != -2 else "undefined!" for i in tree_.feature]
    def recurse(node):
        if tree_.feature[node] == -2:
            return {"type": "leaf", "value": float(tree_.value[node][0][0])}
        return {
            "type": "node",
            "feature": feature_name[node],
            "feature_index": int(tree_.feature[node]),
            "threshold": float(tree_.threshold[node]),
            "left": recurse(tree_.children_left[node]),
            "right": recurse(tree_.children_right[node])
        }
    return recurse(0)

def forest_to_json(model, feature_names):
    if not hasattr(model, "estimators_"): return []
    return [tree_to_json(estimator, feature_names) for estimator in model.estimators_]

# =========================================================
# 3. 시간 계산 유틸리티
# =========================================================
def get_hours_elapsed(time_str):
    """ 'YYYYMMDDHHMM' 문자열을 받아 현재 시간과의 차이(시간) 계산 """
    try:
        last_update = datetime.strptime(str(time_str), "%Y%m%d%H%M")
        diff = datetime.now() - last_update
        return max(0.0, diff.total_seconds() / 3600.0)
    except:
        return 9999.0 # 포맷 오류거나 없으면 오래된 데이터로 간주

# =========================================================
# 4. 민감도 예측 모델 (Core Logic)
# =========================================================
class SensitivityAnalyzer:
    def __init__(self):
        # 목표: 사용자 가중치(Weight) 예측
        self.model = RandomForestRegressor(n_estimators=15, max_depth=6, random_state=42)
        self.is_trained = False
        self.feature_names = ["is_I", "is_S", "is_F", "is_P", "stress", "hrv"]

    def encode_features(self, user):
        mbti = user.get('mbti', 'ISTJ')
        vec = [
            1 if 'I' in mbti else 0,
            1 if 'S' in mbti else 0,
            1 if 'F' in mbti else 0,
            1 if 'P' in mbti else 0
        ]
        metrics = user.get('bodyMetrics') or {}

        # 💡 safe_float_convert 적용 (결측치 및 타입 오류 방지)
        stress = safe_float_convert(metrics.get('stressAvg'), 50.0)
        hrv = safe_float_convert(metrics.get('heartRateVariation'), 10.0)
        vec.append(stress)
        vec.append(hrv)
        return vec

    def train_models(self, user_list):
        X, y = [], []
        valid_cnt = 0
        
        for u in user_list:
            # 1. 최근 수정 여부 확인 (Time Decay)
            updated_at_str = u.get('updatedAt')
            hours_elapsed = get_hours_elapsed(updated_at_str)
            
            # 가중치 1: 최근일수록 높음 (0시간=+3.0 ~ 24시간=+0.1)
            time_bonus = 3.0 / (hours_elapsed + 1.0)
            
            # 가중치 2: 스트레스 높으면 높음
            # 💡 safe_float_convert 적용 (결측치 및 타입 오류 방지)
            stress = safe_float_convert(u.get('bodyMetrics', {}).get('stressAvg'), 50.0)
            stress_bonus = 1.0 if stress >= 80 else (0.5 if stress >= 60 else 0.0)
            
            # 최종 학습 목표값 (Label)
            final_weight = 1.0 + time_bonus + stress_bonus
            
            X.append(self.encode_features(u))
            y.append(final_weight)
            valid_cnt += 1
        
        if valid_cnt < 3:
            print(f"[Server] Not enough data ({valid_cnt}). Skip training.")
            return

        self.model.fit(X, y)
        self.is_trained = True
        print(f"[Server] Model Trained with {valid_cnt} users.")

    def get_model_json(self):
        if not self.is_trained: return None
        return forest_to_json(self.model, self.feature_names)

# =========================================================
# 5. FastAPI 설정
# =========================================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    global sensitivity_model, current_users
    sensitivity_model = SensitivityAnalyzer()
    db_conn = ensure_firebase()
    if db_conn:
        try:
            docs = db_conn.collection("users").stream()
            current_users = [d.to_dict() for d in docs]
            sensitivity_model.train_models(current_users)
        except Exception as e:
            print(f"[Server] Init Error: {e}")
    yield

app = FastAPI(lifespan=lifespan)

@app.get("/weight-model")
def get_weight_model():
    """ [엔드포인트] 학습된 JSON 모델 배포 """
    model_json = sensitivity_model.get_model_json()
    if not model_json: return {"error": "Model not trained"}
    
    return {
        "metadata": {
            "version": "v1.0",
            "logic": "Predicts User Sensitivity (Weight)",
            "features": ["is_I", "is_S", "is_F", "is_P", "stress", "hrv"]
        },
        "model_forest": model_json
    }

class RetrainRequest(BaseModel):
    userId: str

@app.post("/trigger-retrain")
def trigger_retrain(req: RetrainRequest, bg: BackgroundTasks):
    """ 앱이 DB 수정 후 호출하면 재학습 트리거 """
    bg.add_task(reload_and_train)
    return {"status": "ok", "msg": "Retraining started."}

def reload_and_train():
    global current_users
    ensure_firebase()
    try:
        docs = db.collection("users").stream()
        current_users = [d.to_dict() for d in docs]
        sensitivity_model.train_models(current_users)
        print("[Server] DB Reloaded & Retrained.")
    except Exception as e:
        print(f"[Server] Retrain Error: {e}")
