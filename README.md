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

Additionally, PocketHome adapts to **time-based tolerance changes** and **biometric indicators** such as stress levels and heart-rate variability. For example, users who remain in the same environment for a long time gradually become more tolerant, while elevated stress or unusual physiological signals trigger stricter comfort adjustments.

PocketHome is more than just an IoT automation system—it is designed to function as an **intelligent decision-making model capable of balancing multiple users’ satisfaction simultaneously** while dynamically adapting to both behavioral and physiological signals.

---

### **What do you want to see at the end?**
The final goals of this project are as follows:

1. **Develop an AI optimization system that provides a balanced environment for all users**  
   - We mathematically model the satisfaction functions of multiple users with varying preferences.  
   - Based on these models, the AI automatically determines the most fair and stable environmental setting using fuzzy logic and genetic optimization.

2. **Enable continuous improvement through learning from user interactions and physiological signals**  
   - The system updates user models not only when users manually adjust the environment but also when **biometric indicators** (e.g., stress level, heart-rate variability) suggest discomfort.  
   - Additionally, the system incorporates **time-based tolerance adaptation**, allowing user comfort curves to gradually change as time passes.  
   - These factors work together to refine satisfaction models over time.

3. **Create an autonomous environment that requires minimal user intervention**  
   - As the system learns implicit user preferences and physiological states, it gradually converges toward a **Pareto-optimal environmental state** where no user experiences significant discomfort.  
   - The environment reacts proactively when stress is high or when physiological instability is detected, reducing the need for manual adjustments.

4. **Implement a functional prototype integrated with real IoT devices**  
   - Using Firebase for real-time data synchronization, the system can autonomously control HVAC, lighting, and air purification devices based on optimized environmental settings.

Ultimately, our vision is to create **“an environment that adapts to people,” rather than forcing people to adapt to their environment.**  
This is the core mission of the PocketHome project.


# II. Datasets

### **1. Overview**
The dataset used in the PocketHome system includes user environmental preferences, personality traits, time-based adaptation data, and optional biometric information. All data is stored in **Firebase Realtime Database**, allowing the AI engine to dynamically update preferences, re-learn user models, and optimize the environment in real time.

The dataset is used for:
- Constructing fuzzy satisfaction models  
- Predicting missing preferences using MBTI  
- Running multi-user optimization algorithms  
- Adjusting user comfort models using feedback, time decay, and biometric signals  

---

### **2. Data Sources**

#### **(1) User-Provided Static Preferences**
Users directly input their preferred environmental settings through the WorkIn app.

| Parameter | Range | Description |
|----------|--------|-------------|
| Temperature | 18–28°C (0.5 step) | Preferred temperature |
| Humidity | 1–5 | Preferred humidity level |
| Brightness | 0–10 | Preferred brightness |
| MBTI | 4-letter type | Used for preference prediction |

These preferences serve as the baseline for satisfaction modeling.

---

#### **(2) Time-Based Adaptation Data**
Each user contains an `updatedAt` timestamp stored in **UNIX milliseconds**:

```json
"updatedAt": 1763184630661
```

This value is used to compute:

- **timeDiff**: minutes since last update  
- **adaptationFactor = min(timeDiff / 60, 1.0)**

The longer a user remains in the same environment, the **more tolerant** they become, increasing the temperature tolerance dynamically.

---

#### **(3) Biometric Signals (Optional)**
If `useBodyInfo` is enabled, biometric data is included:

```json
"bodyMetrics": {
  "stressAvg": 50,
  "heartRateVariation": 10
}
```

Biometric effects:
- **stressAvg > 70**  
  - target temperature −1.0°C  
  - temperature tolerance ×0.7  
  - satisfaction penalty = (stress% × 0.2)

- **heartRateVariation > 20**  
  - target temperature −0.5°C

These signals help detect hidden discomfort even without manual adjustments.

---

### **3. Firebase Database Structure (Latest Version)**

```json
{
  "userId": "U1",
  "mbti": "ENTP",
  "temperature": 24.1,
  "humidity": 4,
  "brightness": 2,
  "updatedAt": 1763184630661,
  "useBodyInfo": true,
  "bodyMetrics": {
    "stressAvg": 50,
    "heartRateVariation": 10
  }
}
```

Each user profile may include:
- Static preferences  
- MBTI information  
- Time-based adaptation data  
- Biometric indicators  

---

### **4. Dataset Usage in the AI System**

#### **(1) Dynamic Satisfaction Modeling (Fuzzy Logic)**
Temperature satisfaction uses a **dynamic tolerance** influenced by:
- timeSinceLastUpdate  
- stress level  
- heart-rate variability  

Humidity and brightness use fixed tolerances.

---

#### **(2) Preference Prediction (Random Forest)**
Missing preferences are predicted based on MBTI traits using RandomForestRegressor.

---

#### **(3) Optimization Dataset**
Used to compute:
- Minimum satisfaction  
- Average satisfaction  
- A fair multi-user environmental setting via Genetic Algorithm  

---

#### **(4) Feedback & Biometric-Based Updates**
When a user changes an environment value:
- Firebase values update  
- `updatedAt` timestamp refreshes  
- ML models retrain  
- Optimization re-runs  

When biometric triggers activate:
- satisfaction dynamically decreases  
- target temperature shifts  
- tolerance recalculates  

---

### **Summary**
The PocketHome dataset is a **live, adaptive data structure** combining:
- User preferences  
- Personality-based predictions  
- Time-driven tolerance changes  
- Biometric indicators  

This rich dataset enables fair and intelligent multi-user environmental optimization.

# III. Methodology

The PocketHome system follows a three-phase pipeline:  
**(1) Initial Setup and Modeling → (2) Multi-Objective Optimization → (3) Continuous Learning Loop.**  
This ensures that the environment is optimized for multiple users at once and continuously adapts to feedback, time-based tolerance, and biometric signals.

---

## **1. Phase 1: Initial Setup & User Modeling**

### **(1) Collecting User Preferences**
Users enter their preferred temperature, humidity, and brightness levels through the WorkIn app.  
These values, along with MBTI personality types and optional biometric settings, are stored in Firebase Realtime Database.

Example user entry:
```json
{
  "userId": "U1",
  "mbti": "ENTP",
  "temperature": 24.1,
  "humidity": 4,
  "brightness": 2,
  "useBodyInfo": true,
  "updatedAt": 1763184630661
}
```

These static inputs serve as the baseline for satisfaction modeling.

---

### **(2) Satisfaction Function Modeling (Fuzzy Logic with Dynamic Tolerance)**

The system converts each user’s preferences into a continuous satisfaction function using Gaussian-based fuzzy logic:

```math
S(x) = e^{-(x - target)^2 / (2 \cdot tolerance^2)}
```

However, the **tolerance value is dynamic**, influenced by:

- **Time since last update (`updatedAt`)**  
  - Longer duration → higher adaptation factor → wider tolerance  
- **Stress level (bodyMetrics.stressAvg)**  
  - stress > 70 → tolerance × 0.7  
- **Heart-rate variability (bodyMetrics.heartRateVariation)**

This makes temperature satisfaction context-aware and physiologically adaptive.

Weights used:
- Temperature: 50%  
- Humidity: 30%  
- Brightness: 20%

---

### **(3) Biometric and Behavioral Adjustment**

If `useBodyInfo = true`, the system adjusts comfort models using physiological indicators:

- **stressAvg > 70**
  - Target temperature reduced by **1.0°C**
  - Satisfaction penalty = stress% × 0.2
- **heartRateVariation > 20**
  - Target temperature reduced by **0.5°C**

These adjustments help detect hidden discomfort even when the user does not manually change settings.

---

### **(4) Preference Prediction (Random Forest Regression)**
Some users may have missing data.  
To prevent this from breaking the pipeline, the system uses RandomForestRegressor models to predict:

- Temperature  
- Humidity  
- Brightness  

based on MBTI patterns observed in other users.

---

## **2. Phase 2: Multi-Objective Optimization (MOP)**

### **(1) Defining the Objective Function**
The system aggregates satisfaction scores from all users and applies a **Max–Min fairness objective**:

```math
Goal = \max ( \min(S_1, S_2, ..., S_n) )
```

This ensures no user experiences extreme discomfort.

---

### **(2) Optimization via Genetic Algorithm (GA)**  
Search space:

- Temperature (18–28°C, 0.5 step)  
- Humidity (1–5)  
- Brightness (0–10)

Procedure:

1. Generate random environment candidates  
2. Evaluate fitness (minimum + average satisfaction)  
3. Select best candidates  
4. Apply crossover & mutation  
5. Iterate over generations  
6. Return the optimal solution

**Example Output (Actual Program Result)**

```
[설정] 온도:22.5°C / 습도:4 / 조도:5
[예측] 최소:45점 / 평균:73점
```

---

## **3. Phase 3: Continuous Learning Loop**

### **(1) Real-Time Feedback Collection**
- No manual changes → **positive feedback**  
- User changes environment → **negative feedback**

### **(2) Model Update**
- Update Firebase values  
- Recalculate tolerance based on time  
- Apply biometric adjustments  
- Retrain Random Forest  
- Re-run optimization

### **(3) Re-Optimization**
This loop drives the system toward a **Pareto-optimal state** where satisfaction is balanced.

---

## **4. Visualization & Analysis**
The system visualizes:

- Individual satisfaction scores  
- Mean and minimum scores  
- MBTI-based preference differences  

This helps analyze fairness and performance.

---

## **Why These Algorithms?**

- **Fuzzy Logic with dynamic tolerance**  
  Captures human comfort more realistically and adapts to time and biometric signals.

- **Random Forest Regression**  
  Predicts missing values robustly even with small datasets.

- **Genetic Algorithm**  
  Handles non-linear, multi-dimensional search spaces efficiently.

- **Max–Min Objective Function**  
  Ensures fairness in multi-user environments.

---

## **Summary**
PocketHome integrates:

- Fuzzy satisfaction curves  
- Dynamic tolerance (time & biometric-based)  
- Machine learning prediction  
- Genetic optimization  
- Reinforcement-style continuous feedback  

to maintain a fair, adaptive, and intelligent indoor environment.

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
