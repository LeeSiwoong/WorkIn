# Workers & Project
Lee Siwoong, Department of Information System, bluewings02@hanyang.ac.kr
</br>
Jang YuanJae, Department of Information System, semxe123@gmail.com   
Park JaeBeom, Department of Information System, tony0604@hanyang.ac.kr
</br>
AI-driven Environmental Optimization Through Multi-User Preference Mediation [PocketHome]

# PocketHome
'PocketHome' is an AI-based automated control system that creates an optimal environment for multiple people at once. It works by combining user preferences, observed behaviors, and real-time environmental data from sensors in the space. Using this information, the system automatically adjusts shared appliances like heating/cooling systems, air purifiers, and lighting. The AI's main task is to find a balance that keeps the largest number of people comfortable and satisfied. The system's core technology, reinforcement learning, treats any manual adjustments by users as feedback, allowing it to continuously improve how it operates. This learning process reduces the need for people to make changes themselves.

# I. Introduction

### **Motivation: Why are you doing this?**
In modern shared environments such as offices, classrooms, and co-working spaces, multiple users often occupy the same physical area while having different preferences for temperature, humidity, and lighting. However, most existing environmental control systems rely on a single user’s input or apply a uniform setting to everyone. This frequently leads to discomfort for certain individuals and inefficient operation of HVAC and lighting systems.

Furthermore, users generally do not want to repeatedly adjust environmental settings themselves, and the need for continuous manual control often causes inconvenience and stress. To address these issues, we aim to develop an **AI-driven control system that automatically optimizes the environment by incorporating user preferences, behavioral patterns, and real-time biometric and environmental data**.

PocketHome is more than just an IoT automation system—it is designed to function as an **intelligent decision-making model capable of balancing multiple users’ satisfaction simultaneously**.

---

### **What do you want to see at the end?**
The final goals of this project are as follows:

1. **Develop an AI optimization system that provides a balanced environment for all users**  
   - We mathematically model the satisfaction functions of multiple users with varying preferences.  
   - Based on these models, the AI automatically determines the most fair and stable environmental setting.

2. **Enable continuous improvement through learning from user interactions**  
   - Using reinforcement learning, the system interprets user adjustments (e.g., changing the temperature manually) as feedback.  
   - This feedback is used to refine individual satisfaction models over time.

3. **Create an autonomous environment that requires minimal user intervention**  
   - As the system learns implicit user preferences, it gradually converges toward a **Pareto-optimal environmental state** where no user experiences significant discomfort.

4. **Implement a functional prototype integrated with real IoT devices**  
   - Using Firebase for real-time data synchronization, the system can autonomously control HVAC, lighting, and air purification devices.

Ultimately, our vision is to create **“an environment that adapts to people,” rather than forcing people to adapt to their environment.**  
This is the core mission of the PocketHome project.

# II. Datasets

### **1. Overview**
The dataset used in the PocketHome system consists of multi-user environmental preferences and personality traits. All data is stored and updated in **Firebase Realtime Database**, allowing the AI system to dynamically read user profiles, predict missing values, and perform optimization based on real-time user information.

The dataset is used for:
- Constructing satisfaction models for each user  
- Predicting missing preferences from MBTI  
- Running multi-objective optimization algorithms  
- Updating user preference models after feedback  

---

### **2. Data Sources**

#### **(1) User-Provided Static Preferences**
Users directly input their preferred environmental settings through the WorkIn app. These serve as the core dataset for initial modeling.

| Parameter | Range | Description |
|----------|--------|-------------|
| Temperature | 18–28°C (0.5 step) | Desired room temperature |
| Humidity | 1–5 | Preferred humidity level |
| Brightness | 0–10 | Preferred lighting level |
| MBTI | 4-letter type | Personality trait used for ML-based prediction (may contain missing values) |

These values are stored per user in Firebase and retrieved by the AI engine.

---

### **3. Firebase Database Structure**
The live dataset is structured as follows:
<img width="230" height="306" alt="image" src="https://github.com/user-attachments/assets/3566e42a-310c-40e9-8b20-a041ba79c9a9" />

Each user has a profile that may contain partial or full preferences.

---

### **4. Dataset Usage in the AI System**

#### **(1) Nonlinear Satisfaction Modeling (Fuzzy Logic)**
Each user’s temperature, humidity, and brightness preferences are transformed into a continuous satisfaction score using Gaussian-based fuzzy logic.  
This allows the system to compute how close the current environment is to each user’s ideal condition.

---

#### **(2) Preference Prediction (Random Forest Regression)**
If a user has incomplete data (e.g., missing temperature or humidity values), the system predicts these values using Random Forest models trained on MBTI → preference mappings.

This prevents missing data from disrupting optimization.

---

#### **(3) Optimization Dataset**
The dataset is used to evaluate:
- Minimum satisfaction score  
- Average satisfaction score  
- Best environment setting for multiple users  

During optimization, thousands of virtual environment combinations are scored using these datasets.

---

#### **(4) Feedback-Based Updates**
When a user manually adjusts temperature, humidity, or lighting:
- The value is updated in Firebase  
- The ML model is retrained  
- Optimization is recalculated  

This makes the dataset **dynamic**, always reflecting the latest user behavior.

---

### **5. Notes on Future Expansion**
Biometric data (e.g., heart rate fluctuations, oxygen saturation) and behavioral signals are *not yet included* in the current dataset.  
However, these elements are planned for future versions and can further enhance accuracy in satisfaction modeling and reinforcement learning.

---

### **Summary**
The PocketHome dataset is a live collection of user preferences and personality-based features stored in Firebase. It enables real-time modeling, prediction, optimization, and adaptive control of shared indoor environments.

# III. Methodology

The PocketHome system follows a three-phase pipeline:  
**(1) Initial Setup and Modeling → (2) Multi-Objective Optimization → (3) Continuous Learning Loop.**  
This ensures that the environment is optimized for multiple users at once and continuously adapts to feedback.

---

## **1. Phase 1: Initial Setup & User Modeling**

### **(1) Collecting User Preferences**
Users enter their preferred temperature, humidity, and brightness levels through the WorkIn app.  
These values, along with MBTI personality types, are stored in Firebase Realtime Database.

Example user entry:
```json
{
  "userId": "U1",
  "mbti": "ENTP",
  "mbtiEI": "E",
  "mbtiNS": "N",
  "mbtiPJ": "P",
  "mbtiTF": "T",
  "temperature": 24.1,
  "humidity": 4,
  "brightness": 2,
  "useBodyInfo": false,
  "updatedAt": 1763184630661
}
```

These static inputs serve as the baseline for satisfaction modeling.

---

### **(2) Satisfaction Function Modeling (Fuzzy Logic)**  
The system converts each user's preferences into a **continuous satisfaction function** using Gaussian-based fuzzy logic:

```math
S(x) = e^{-(x - target)^2 / (2 \cdot tolerance^2)}
```


- The closer the environment is to the preferred value, the higher the satisfaction score.  
- Different weights are used:  
  - Temperature: 50%  
  - Humidity: 30%  
  - Brightness: 20%

This creates individualized comfort curves for every user.

---

### **(3) Preference Prediction (Random Forest Regression)**  
Some users may have incomplete data (e.g., only an MBTI type).  
To prevent missing values from breaking the optimization pipeline, the system predicts missing parameters using RandomForestRegressor models:

- Temperature Model  
- Humidity Model  
- Brightness Model  

Training data comes from existing user entries.  
This enables the system to infer environmental preferences from personality traits.

---

## **2. Phase 2: Multi-Objective Optimization (MOP)**

### **(1) Defining the Objective Function**
To determine the “best” environment, the system aggregates satisfaction scores from all active users.

PocketHome uses a **Max–Min fairness strategy**:

- The optimal environment is the one that **maximizes the minimum satisfaction** among all users.  
- Ensures fairness and prevents any user from experiencing extreme discomfort.

```math
Goal = max( min(S_1, S_2, ..., S_n) )
```

---

### **(2) Optimization via Genetic Algorithm (GA)**  
To search through thousands of possible combinations of:

- Temperature (18–28°C, 0.5 steps)  
- Humidity (1–5)  
- Brightness (0–10)

The system uses a Genetic Algorithm:

1. **Generate random candidate environments**  
2. **Evaluate fitness** (minimum + average satisfaction)  
3. **Select best-performing candidates**  
4. **Apply crossover & mutation**  
5. **Iterate** over generations  
6. **Return the optimal solution**

**Final Output Example (Actual Program Result)**

```
[System] 100명 데이터 학습 완료

============================================================
 ■ PocketHome 최적화 결과
  [설정] 온도:22.5°C / 습도:4 / 조도:5
  [예측] 최소:45점 / 평균:73점
------------------------------------------------------------
[AI Data Analysis] MBTI 성향별 선호도 차이
 ■ 에너지 (E vs I): 온도 차이 미미함
 ■ 인식 (N vs S): 'N' 성향이 약 0.5°C 높게 선호
 ■ 판단 (T vs F): 'T' 성향이 약 1.0°C 높게 선호
 ■ 생활 (J vs P): 온도 차이 미미함
============================================================
```


---

## **3. Phase 3: Continuous Learning Loop (Reinforcement Learning Concept)**  

### **(1) Real-Time Feedback Collection**
While the environment is applied:

- If users do **not** manually change temperature/humidity/light → **positive feedback**  
- If a user **manually adjusts** a setting → **negative feedback**

This feedback indicates whether the current optimized environment matches real user comfort.

---

### **(2) Model Update After Feedback**
When negative feedback occurs:

- The user's stored preference in Firebase is updated  
- The satisfaction model is recalibrated  
- The Random Forest predictor is retrained  
- Optimization is re-run with new user data

This mimics the behavior of reinforcement learning, where the system continuously adapts based on interaction.

---

### **(3) Re-Optimization & Environment Adjustment**
After updating preferences:

1. Run Genetic Algorithm again  
2. Compute a new optimal environment  
3. Apply updated settings  
4. Repeat the loop

This leads the system to eventually converge to a **Pareto-optimal** environment where everyone experiences balanced comfort.

---

## **4. Visualization & Analysis**
The system uses `matplotlib` to generate graphs showing:

- Individual satisfaction scores  
- Average satisfaction  
- Minimum satisfaction  

This visual feedback helps evaluate how fair and effective the optimized environment is for a group.

---

### Why These Algorithms?

- **Fuzzy Logic**  
  Used to model non-linear human satisfaction. Environmental comfort is not a linear function, and fuzzy Gaussian curves fit real human perception more naturally.

- **Random Forest (scikit-learn)**  
  Chosen for predicting missing preferences from MBTI. It handles small datasets well, prevents overfitting, and is easy to train dynamically.

- **Genetic Algorithm**  
  Optimal for searching large combination spaces (temperature × humidity × brightness). Traditional gradient-based methods cannot be used due to the non-differentiable satisfaction function.

- **Max–Min objective function**  
  Ensures fairness by maximizing the minimum satisfaction rather than total sum. Perfect for shared spaces where equality matters.

### Code Features

- `calculate_satisfaction()` implements Gaussian fuzzy scoring.
- `RandomForestRegressor` predicts missing environmental preferences.
- `optimize_environment()` performs GA optimization over thousands of virtual environments.
- `apply_feedback()` updates Firebase data and retrains the model dynamically.
- `show_graph()` visualizes satisfaction distribution with min/avg lines


## **Summary**
The PocketHome methodology combines:

- Fuzzy Logic  
- Machine Learning (Random Forest)  
- Genetic Algorithms  
- Real-time feedback adaptation  

to create a dynamic, fair, and continuously improving AI-driven environmental control system.

# IV. Evaluation & Analysis

This section evaluates how effectively PocketHome optimizes a shared environment for multiple users.  
The analysis is based on (1) optimization output logs, (2) MBTI trend analysis, and  
(3) satisfaction distribution visualizations.

---

## **1. Optimization Output Summary**

When the AI runs the optimization process, the system prints the following:

```
[설정] 온도:22.5°C / 습도:4 / 조도:5
[예측] 최소:45점 / 평균:73점
```

### Interpretation
- **Temperature = 22.5°C, Humidity = 4, Brightness = 5**  
  → The Genetic Algorithm identified this as the fairest shared environment.
- **Minimum satisfaction = 45점**  
  → Even the least satisfied user maintains moderate comfort.
- **Average satisfaction = 73점**  
  → Most users experience high comfort.

This confirms that the Max–Min optimization objective is functioning as intended.

---

## **2. MBTI-Based Preference Analysis**

The system also analyzes MBTI traits and their correlation with temperature preferences:

```
에너지 (E vs I): 온도 차이 미미함  
인식 (N vs S): 'N' 성향이 약 0.5°C 높게 선호  
판단 (T vs F): 'T' 성향이 약 1.0°C 높게 선호  
생활 (J vs P): 온도 차이 미미함
```

### Insights
- **N** types prefer slightly warmer environments.
- **T** types prefer noticeably warmer environments.
- **E/I** and **J/P** traits contribute less to variation.

This demonstrates that personality-based prediction (Random Forest) enhances preference estimation when values are missing.

---

## **3. Satisfaction Distribution Graph**

The graph below visualizes:
- Each user’s satisfaction score (0–100)
- The **average satisfaction line** (green)
- The **minimum satisfaction line** (red)

This helps validate the fairness of the optimized environment.

### 📊 User Satisfaction Graph

<img width="600" height="300" alt="image" src="https://github.com/user-attachments/assets/41ab23b5-5956-4b8c-86f5-533af4571c66" />


### Interpretation of Graph
- Users generally fall between **55–95 points**, indicating high comfort.
- The **average line (약 73점)** shows the overall comfort stability.
- The **minimum line (약 42점)** indicates only a small subset of users experience lower comfort.
- The optimization ensures no user falls extremely low, fulfilling the fairness requirement.

---

## **4. Feedback → Retraining → Re-Optimization**

When a user manually adjusts the environment, the model updates:

```
U1 hum 4  
-> 모델 재학습 중...  
[System] 100명 데이터 학습 완료
```

A new optimal environment is produced:

```
[설정] 온도:23.0°C / 습도:3 / 조도:4
[예측] 최소:45점 / 평균:74점
```

### What This Means
- User dissatisfaction triggers recalibration.
- Reinforcement-style learning adjusts preference weights.
- The system re-optimizes with updated data.
- Average satisfaction improved (73 → 74).

This demonstrates **adaptive learning** and confirms the system responds correctly to real feedback.

---

## **5. Summary**

- The GA consistently selects balanced environmental settings.  
- Satisfaction distribution shows fairness (high avg, stable min).  
- MBTI analysis contributes to missing-value prediction accuracy.  
- Graph visualization clearly reveals comfort trends.  
- Feedback updates prove adaptive behavior over time.

PocketHome successfully achieves fair, data-driven multi-user environmental optimization.
