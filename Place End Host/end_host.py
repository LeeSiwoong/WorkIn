#각 공간 별 단말 (엔드 호스트) 용 코드

import firebase_admin
from firebase_admin import credentials, firestore
import requests
import json
import time
from datetime import datetime

# =========================================================
# 1. 설정
# =========================================================
KEY_FILE = "serviceAccountKey.json"  # 엔드 호스트에도 키 파일 필요
AI_SERVER_URL = "http://localhost:8000/weight-model" # VM IP로 변경 필요

class SmartHomeEndHost:
    def __init__(self):
        # Firebase 초기화
        if not firebase_admin._apps:
            cred = credentials.Certificate(KEY_FILE)
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()
        
        # AI 모델 로드
        self.weight_model = None
        self.load_ai_model()

    def load_ai_model(self):
        """ 서버에서 최신 지능(JSON) 다운로드 """
        try:
            print("[Client] Fetching AI Model...")
            res = requests.get(AI_SERVER_URL, timeout=5)
            if res.status_code == 200:
                self.weight_model = res.json().get('model_forest')
                print("[Client] AI Model Loaded Successfully.")
            else:
                print(f"[Client] Server Error: {res.status_code}")
        except Exception as e:
            print(f"[Client] Connection Failed: {e}")

    # =====================================================
    # 2. 추론 엔진 (Inference Engine)
    # =====================================================
    def _traverse(self, node, features):
        if node['type'] == 'leaf': return node['value']
        idx = node['feature_index']
        if features[idx] <= node['threshold']:
            return self._traverse(node['left'], features)
        else:
            return self._traverse(node['right'], features)

    def predict_weight(self, features):
        if not self.weight_model: return 1.0
        total = 0
        for tree in self.weight_model:
            total += self._traverse(tree, features)
        return total / len(self.weight_model)

    def calculate_time_bonus(self, time_str):
        try:
            last = datetime.strptime(str(time_str), "%Y%m%d%H%M")
            diff = (datetime.now() - last).total_seconds() / 3600.0
            return 3.0 / (max(0, diff) + 1.0)
        except: return 0.0

    def get_features(self, user):
        mbti = user.get('mbti', 'ISTJ')
        metrics = user.get('bodyMetrics') or {}
        return [
            1 if 'I' in mbti else 0, 1 if 'S' in mbti else 0,
            1 if 'F' in mbti else 0, 1 if 'P' in mbti else 0,
            float(metrics.get('stressAvg', 50)),
            float(metrics.get('heartRateVariation', 10))
        ]

    # =====================================================
    # 3. 최적화 로직 (Optimization Logic)
    # =====================================================
    def optimize(self, user_ids):
        if not user_ids: return
        
        print(f"\n--- Optimizing for users: {user_ids} ---")
        weighted_sums = {'temp': 0, 'hum': 0, 'light': 0}
        total_weight = 0

        for uid in user_ids:
            # A. DB에서 최신 정보 조회 (실시간성)
            doc = self.db.collection('users').document(uid).get()
            if not doc.exists: continue
            u = doc.to_dict()

            # B. 가중치 계산 (AI 예측 + 시간 보너스)
            features = self.get_features(u)
            ai_w = self.predict_weight(features)
            time_w = self.calculate_time_bonus(u.get('updatedAt'))
            final_w = ai_w + time_w

            print(f" > User[{uid}] Target:{u.get('temperature')} | Weight: {final_w:.2f} (AI:{ai_w:.2f} + Time:{time_w:.2f})")

            # C. 가중 합계 누적
            weighted_sums['temp'] += float(u.get('temperature', 24)) * final_w
            weighted_sums['hum'] += int(u.get('humidity', 3)) * final_w
            weighted_sums['light'] += int(u.get('brightness', 5)) * final_w
            total_weight += final_w

        if total_weight == 0: return

        # D. 최종 단일값 도출
        final_env = {
            'temp': round(weighted_sums['temp'] / total_weight, 1),
            'hum': int(round(weighted_sums['hum'] / total_weight)),
            'light': int(round(weighted_sums['light'] / total_weight))
        }
        
        print(f"▶ [FINAL DECISION] Temp: {final_env['temp']}°C / Hum: {final_env['hum']} / Light: {final_env['light']}")
        # Hardware Control Code Here...

# =========================================================
# 4. 실행
# =========================================================
if __name__ == "__main__":
    host = SmartHomeEndHost()
    
    # 예시: 센서가 감지한 ID 리스트
    detected_users = ["test_user_1", "test_user_2"] 
    
    # 주기적으로 실행
    host.optimize(detected_users)