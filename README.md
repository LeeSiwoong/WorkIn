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
In modern shared environments such as offices, classrooms, and co-working spaces, **multiple users often occupy the same physical area while having different preferences** for temperature, humidity, and lighting. However, most existing environmental control systems rely on **a single user’s input** or apply **a uniform setting** to everyone. This frequently leads to discomfort for certain individuals and inefficient operation of HVAC and lighting systems.

Furthermore, users generally do not want to repeatedly adjust environmental settings themselves, and the need for continuous manual control often causes inconvenience and stress. To address these issues, we aim to develop an **AI-driven control system that automatically optimizes the environment by incorporating user preferences, behavioral patterns, and real-time biometric and environmental data**.

Additionally, PocketHome adapts to **time-based changes in user sensitivity** and **biometric indicators** such as stress levels and heart-rate variability. For example, users who remain in the same environment for a long time may gradually become less sensitive to small changes, while elevated stress or unusual physiological signals trigger stricter or more cautious adjustments.

PocketHome is more than just an IoT automation system—it is designed to function as an **intelligent decision-making model capable of balancing multiple users’ satisfaction simultaneously**, while dynamically adapting to both behavioral and physiological signals.

---

### **What do you want to see at the end?**
The final goals of this project are as follows:

1. **Develop an AI-driven environment control system that fairly reflects all users' needs**  
   - Instead of relying on a single fixed satisfaction function, PocketHome learns **user sensitivity (weight)** based on personality traits, behavior patterns, and biometric conditions.  
   - The system uses these learned weights to determine a fair and stable environmental setting for the entire group.

2. **Enable continuous improvement through real-time data and biometric signals**  
   - The AI model updates user weights not only when users manually adjust the environment but also when **physiological indicators** (e.g., stress level, heart-rate variability) detect discomfort.  
   - Additionally, the system incorporates **time-based sensitivity decay**, allowing a user’s influence to change naturally over time.  
   - These dynamic factors enable PocketHome to adapt continuously as user conditions shift.

3. **Create an autonomous environment that minimizes user intervention**  
   - By learning implicit user tendencies—such as when users are stressed, calm, or acclimated—the system generates environment settings that reduce the need for manual control.  
   - The model aims to reach **a stable equilibrium** where all users’ influences are proportionally balanced according to their current sensitivity levels.

4. **Implement a functional client–server prototype connected with real IoT and mobile systems**  
   - The **mobile app** collects user preferences and biometric data into Firebase Firestore.  
   - The **AI server** trains and updates the weight model, providing real-time model parameters to end-host devices.  
   - **End hosts** compute the final environment setting using the server-provided weights and apply it to local IoT devices.

Ultimately, our vision is to create **“an environment that adapts to people,” rather than forcing people to adapt to their environment.”**  
This reflects the core mission of the PocketHome project.


# II. Datasets

### **1. Overview**
The PocketHome system uses a unified dataset stored in **Firebase Firestore**.  
Each user is represented as a document containing:

- Environmental preferences (temperature, humidity, brightness)  
- Personality traits (MBTI and its decomposed dimensions)  
- Optional biometric information (stress level, heart-rate variation)  
- Time-related metadata indicating how recent the data is  

This dataset is primarily used by the **Weight Model Server**, which:

- Reads user documents from Firestore  
- Learns how strongly each user should influence the final environment (user weight)  
- Exports the learned model as a JSON structure for end-host devices

End-host devices then use:

- The latest user documents from Firestore  
- The weight model provided by the server  

to compute a **weighted environmental setting** (temperature, humidity, brightness) that reflects the influence of all users fairly and adaptively.

---

### **2. Data Sources**

PocketHome uses four main categories of data for each user.

---

#### **(1) User-Provided Environmental Preferences**

Users directly input their preferred environment through the mobile app.

| Parameter   | Range              | Description                |
|------------|--------------------|----------------------------|
| temperature | 18–28°C (0.1 step) | Preferred room temperature |
| humidity    | 1–5                | Preferred humidity level   |
| brightness  | 1–10               | Preferred light level      |

These values represent the user’s baseline environmental choices.

---

#### **(2) Personality Traits (MBTI Decomposed)**

The system stores both the overall MBTI string and each MBTI dimension separately:

```json
{
  "mbti": "ENTP",
  "mbtiEI": "E",
  "mbtiNS": "N",
  "mbtiTF": "T",
  "mbtiPJ": "P"
}
```
---

#### **(3) Biometric Measurements (Optional)**
If the user allows biometric usage, the app uploads recent physiological information:

```json
"useBodyInfo": true,
"bodyMetrics": {
  "collectedAt": "202512021959",
  "stressAvg": 63,
  "heartRateVariation": 12
}
```
- collectedAt : Timestamp of when the biometric data was measured

- stressAvg : Average stress score during a recent period

- heartRateVariation : Variation in heart rate (proxy for physiological fluctuation)

#### **(4) Time-Based Sensitivity Metadata**

Each user document stores a timestamp indicating when their preferences were last updated:

```json
{
  "updatedAt": "202512022210"
}
```

---

### **3. Firestore Database Structure (Latest Version)**

```json
{
  "userId": "U1",
  "mbti": "ENTP",
  "mbtiEI": "E",
  "mbtiNS": "N",
  "mbtiTF": "T",
  "mbtiPJ": "P",

  "temperature": 24.1,
  "humidity": 4,
  "brightness": 2,

  "updatedAt": "202512022210",

  "useBodyInfo": true,
  "bodyMetrics": {
    "collectedAt": "2025-12-02T17:29:37.573324",
    "stressAvg": 63,
    "heartRateVariation": 12
  }
}
```

Each user profile may include:
- Static environmental preferences (temperature, humidity, brightness)
- MBTI type and decomposed personality dimensions (mbtiEI, mbtiNS, mbtiTF, mbtiPJ)
- Time-based metadata (updatedAt) for sensitivity decay 
- Optional biometric indicators under bodyMetrics (stressAvg, heartRateVariation, collectedAt)

---

### **4. Dataset Usage in the AI System**

The PocketHome system uses the Firestore dataset in two main components:
1. The **Weight Model Server**, which learns how strongly each user should influence the final environment
2. The **End-Host Device**, which calculates the shared environmental settings

#### **(1) Weight Model Training (Server-Side)**
The server reads user documents from Firestore and converts them into feature vectors.
Each user contributes the following types of data:
- Environmental preferences  
- Personality traits (full MBTI + decomposed fields)
- Optional biometric indicators
- Time-based freshness information

Based on these values, the server generates a **weight label** for each user:
- Higher stress → higher weight
- Recent updates → higher weight
- Stale data → lower weight
- Missing biometric data → neutral/ignored

A RandomForestRegressor is trained to predict weights.

The trained model is exported as JSON and served through the following endpoint:
```bash
GET /weight-model
```

---

#### **(2) Model-Based Environment Calculation (End Host)**
The end host performs three steps:
**1.** Fetch user data from Firestore

**2.** Download the latest weight model from the server

**3.** Compute the weighted environmental settings

Weighted average formula:
```java
Final Temperature = Σ(weight_i × temp_i) / Σ(weight_i)
Final Humidity    = Σ(weight_i × hum_i) / Σ(weight_i)
Final Brightness  = Σ(weight_i × bright_i) / Σ(weight_i)
```
This ensures that:
- Users under greater stress influence the result more

- Users with recent updates weigh more

- Users with outdated or missing data weigh less

- MBTI traits contribute subtle adjustments
---

#### **(3) Continuous Adaptation**
Whenever any user updates:
- their environmental preferences

- their MBTI information

- their biometric data

- or simply when time passes

PocketHome automatically adapts:
- The weight model retrains

- End-host devices recalculate the environment

- The applied environment updates dynamically

This enables PocketHome to continuously reflect both behavioral and physiological changes.

---

---

### **Summary**
The Firestore dataset powers the entire AI pipeline by providing:
- Environmental preferences

- Personality traits

- Time-based metadata

- Biometric signals

The Weight Model Server learns weights, and End-Host devices compute the real-time shared environment using these learned weights.

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
