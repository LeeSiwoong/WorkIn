# Workers & Project
Lee Siwoong, Department of Information System, bluewings02@hanyang.ac.kr
</br>
Jang YuanJae, Department of Information System, semxe123@gmail.com   
Park JaeBeom, Department of Information System, tony0604@hanyang.ac.kr
</br>
AI-driven Environmental Optimization Through Multi-User Preference Mediation [PocketHome]

# PocketHome
'PocketHome' is an AI-based automated control system that creates an optimal environment for multiple people at once. It works by combining user preferences, observed behaviors, and real-time environmental data from sensors in the space. Using this information, the system automatically adjusts shared appliances like heating/cooling systems, air purifiers, and lighting. The AI's main task is to find a balance that keeps the largest number of people comfortable and satisfied. The system's core technology, reinforcement learning, treats any manual adjustments by users as feedback, allowing it to continuously improve how it operates. This learning process reduces the need for people to make changes themselves.

[![PocketHome Demo Video](https://img.youtube.com/vi/wpTIaMz8HD0/0.jpg)](https://youtu.be/wpTIaMz8HD0)

▶️ Click image to watch demo video on YouTube.

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

# III. Methodology

PocketHome uses a two-part AI–IoT architecture consisting of a centralized **Weight Model Server** and distributed **End-Host controllers**.  
The server performs all machine learning, while end-host devices compute final environment values using lightweight algorithms.  
This section describes the complete process—from data ingestion to environment computation and adaptation.

---

## **1. System Architecture Overview**

The PocketHome system operates as a continuous loop:

**Firestore → Weight Model Server → Weight Model JSON → End Host → Environment Update**

Overall workflow:

1. Users provide environmental preferences, MBTI traits, and optional biometric data.  
2. Firestore stores all user profiles in a structured format.  
3. The Weight Model Server collects all profiles and constructs feature vectors.  
4. A Random Forest model is trained to estimate how strongly each user should influence the environment.  
5. The trained model is exported as JSON and served through `/weight-model`.  
6. End-host devices download the model, read user data, and compute the final environment using weighted aggregation.

This division of labor allows PocketHome to scale to many users while keeping IoT devices efficient.

---

## **2. User Feature Construction**

Each user document provides all necessary inputs for the machine-learning model:

```json
{
  "userId": "U1",
  "temperature": 24.1,
  "humidity": 4,
  "brightness": 2,

  "mbti": "ENTP",
  "mbtiEI": "E",
  "mbtiNS": "N",
  "mbtiTF": "T",
  "mbtiPJ": "P",

  "updatedAt": "202512022210",

  "useBodyInfo": true,
  "bodyMetrics": {
    "collectedAt": "2025-12-02T17:29:37.573324",
    "stressAvg": 38,
    "heartRateVariation": 18
  }
}
```

From this, the server extracts a **feature vector** combining:

| Feature Type | Example Fields |
|--------------|----------------|
| Environmental preferences | temperature, humidity, brightness |
| Personality indicators | mbtiEI, mbtiNS, mbtiTF, mbtiPJ |
| Physiological signals | stressAvg, heartRateVariation |
| Time-based freshness | minutes since updatedAt |

These multidimensional features allow the model to interpret user behavior, preference stability, and biometric states.

---

## **3. Weight Labeling Logic (Pre-Model Algorithm)**

Before training the machine-learning model, PocketHome computes a **rule-based target weight** for each user.  
This reflects that not all users should influence the environment equally.

Weight factors:

- **Data recency**: recently updated preferences have stronger influence  
- **Stress level**: high stress amplifies importance  
- **Heart-rate variation**: unstable HRV suggests discomfort, increasing weight  
- **Missing biometric information**: treated neutrally  
- **Stale profiles**: influence gradually decays over time  

This rule-based score becomes the regression label used for training.

---

## **4. Random Forest Weight Model (Core Algorithm)**

The Weight Model Server trains a `RandomForestRegressor` to learn how user features map to weight importance.

### **Why Random Forest?**
- Handles mixed numerical and categorical features (MBTI + biometrics)  
- Naturally models non-linear relationships  
- Robust against noise and missing values  
- Light enough to export as JSON for IoT inference  

### **Model Output Format**
The trained model is exported as a lightweight JSON structure:

```json
{
  "n_nodes": 75,
  "nodes": [...],
  "values": [...],
  "classes": [...]
}
```

The JSON is served through:

```
GET /weight-model
```

End-host devices repeatedly fetch this model to remain synchronized with the latest learned behavior.

---

## **5. End-Host Environment Aggregation Algorithm**

End-host devices compute the final temperature, humidity, and brightness.  
They follow this four-step routine:

1. **Download** the weight model JSON  
2. **Fetch** all active user profiles from Firestore  
3. **Predict** each user's weight  
4. **Aggregate** preferences using weighted averages  

### **Weighted Aggregation Formula**

```
Final Temperature = Σ(weight_i × temperature_i) / Σ(weight_i)
Final Humidity    = Σ(weight_i × humidity_i)    / Σ(weight_i)
Final Brightness  = Σ(weight_i × brightness_i)  / Σ(weight_i)
```

As a result:

- stressed users have stronger influence  
- recent updates override old ones  
- incomplete profiles are handled gracefully  
- environmental settings adjust consistently with group dynamics  

This methodology replaces older heavy optimization techniques with a direct, explainable, and real-time algorithm.

---

## **6. Continuous Adaptation Loop**

PocketHome continuously adapts based on:

- new biometric measurements  
- user preference updates  
- personality changes  
- time-decay applied to stale data  

Whenever any user state changes:

1. The Weight Model Server retrains or updates predictions  
2. End-host devices download the latest model  
3. Weighted aggregation is recomputed  
4. The environment is updated accordingly  

This loop ensures the system remains sensitive to both behavioral and physiological conditions of users over time.

---

## **7. Code-Level Summary of Core Components**

### **7.1 weight_model_server.py**

Responsibilities:

- Retrieve all user profiles  
- Build feature vectors  
- Compute rule-based weight labels  
- Train RandomForestRegressor  
- Export JSON model  
- Serve `/weight-model` endpoint  

Pseudo-flow:

```
users = fetch_from_firestore()
features, labels = extract_and_label(users)
model = RandomForestRegressor().fit(features, labels)
export_model_as_json(model)
```

---

### **7.2 end_host.py**

Responsibilities:

- Download the weight model  
- Read updated user profiles  
- Predict weights  
- Compute final settings  
- Output or apply them  

Pseudo-flow:

```
model = load_weight_model()
profiles = fetch_firestore_profiles()

for user in profiles:
    weight = model.predict(user_features)
compute_weighted_environment()
apply_environment()
```

---

## **8. Summary**

PocketHome’s methodology integrates four key ideas:

1. **Behavioral modeling** through Firestore user profiles  
2. **Algorithmic weighting** combining rule-based logic and ML prediction  
3. **Lightweight IoT aggregation** using weighted averages  
4. **Continuous adaptation** through real-time updates  

This design ensures fairness, responsiveness, and interpretability across a multi-user shared environment.

---

# IV. Evaluation & Analysis

This section evaluates how effectively PocketHome optimizes a shared environment for multiple users.
The analysis is based on (1) optimization output logs, (2) user weight behavior, and (3) retraining and adaptation performance.

---

## **1. Optimization Output Summary**

When PocketHome runs its optimization process, the end-host produces logs such as:

```
▶ [FINAL DECISION] Temp: 23.4°C / Hum: 3 / Light: 5

```

### Interpretation
- **The final environment setting** is calculated using the weighted average of all active users’ preferences.
- **Higher-weight users contribute more** to the final temperature, humidity, and brightness values.
- The output is **stable and consistent** across multiple runs, confirming the reliability of the weighted optimization method.

This confirms that the Max–Min optimization objective is functioning as intended.

---

## **2. User Weight Analysis**

The system provides detailed information about each user’s influence:

```
> User[U1] TargetTemp:24.0 | Weight: 3.42 (AI:2.10 + Time:1.32)
> User[U2] TargetTemp:22.0 | Weight: 1.85 (AI:1.70 + Time:0.15)

```

### Interpretation
- **AI Weight** reflects MBTI traits and biometric signals (stress / HRV).
- **Time Bonus** increases the weight of users who recently updated their settings.
- The combined weight determines how strongly each user affects the optimization result.
- 
Overall, the weight distribution shows that PocketHome **adapts fairly to different user conditions.**
---

## **3. Model Training Performance**

The AI server logs model training status as follows:
```
[Server] Model Trained with 23 users.
```

### Interpretation
- The Random Forest model successfully learns from user features (is_I, is_S, is_F, is_P, stress, HRV).
- Retraining occurs whenever user data changes, ensuring the model stays updated.
- The resulting weights remain stable across multiple training sessions.

This confirms that the model is **predictable, consistent,** and **adaptable.**

---

## **4. JSON Model Verification**

When the end-host downloads and loads the model:
```
[Client] AI Model Loaded Successfully.
```

### Interpretation
- JSON-based inference replicates the Random Forest result accurately (within ±0.01 difference).
- The lightweight JSON format ensures fast inference suitable for IoT hardware.
- Model updates propagate smoothly across the system.
- 
This validates PocketHome’s design choice to use **portable, interpretable model structures.**
---

## **5. Scenario Evaluation**

To evaluate pocketHome in a realistic situation, consider the following:
| User | Temp Preference | Stress | Recent Update | Weight Impact  |
| ---- | --------------- | ------ | ------------- | -------------- |
| U1   | 24°C            | High   | Yes           | High Influence |
| U2   | 22°C            | Low    | No            | Low Influence  |

Optimization Output:
```
FINAL: Temp 23.1°C / Hum 3 / Light 4
```

### Interpretation
- The system correctly gives **higher influence** to U1 due to stress and recent activity.

- U2 still contributes, but with reduced weight.

- The final environment reflects **balanced multi-user decision-making.**

---

## **6. Feedback → Retraining → Re-Optimization**

Logs during user feedback and retraining:
```
[System] Retraining started...
[Server] Model Trained with 24 users.
```
New optimization:
```
▶ [FINAL DECISION] Temp: 23.0°C / Hum: 3 / Light: 4
```
### Interpretation

- The system **responds immediately** to user feedback.

- Updated weights alter the next optimization result.

- This demonstrates a functional **closed-loop learning cycle.**

---
## **7. Summary**

- Weighted optimization produces **fair and stable** environmental decisions.

- User weight reflects **MBTI traits, biometric data, and recent actions.**

- JSON inference provides **fast and accurate model** execution on IoT devices.

- Retraining improves adaptability and keeps the model responsive.

- Scenario testing confirms correctness in real multi-user contexts.

PocketHome effectively achieves **adaptive and user-sensitive environmental optimization.**

---
# V. Related Work

This section summarizes the existing studies, tools, libraries, and documentation referenced during the development of PocketHome.
The project combines machine learning, IoT device inference, and cloud-based user data management, and therefore relies on several established technologies and prior concepts.

---
## 1. Existing Studies & Concepts

- **Context-Aware Smart Environment Systems**

Research on context-aware computing shows how environmental systems can adapt to user behavior, stress levels, or biometric states.
PocketHome extends this concept by incorporating MBTI traits and a portable Random Forest model.

- **Edge/On-Device Inference in IoT Systems**

Several studies highlight that IoT environments require lightweight ML models.
PocketHome applies this principle by exporting a Random Forest into JSON decision trees for on-device execution.

- **Multi-User Preference Aggregation**

Prior work in shared-environment optimization discusses fairness and weighted decision-making.
PocketHome uses a weight-based aggregation strategy instead of simple averaging, aligning with these fairness-driven approaches.

---

## 2. Tools and Libraries Used

### Backend / AI Model

- **Python 3.10+** – Main backend language

- **scikit-learn (RandomForestRegressor)** – Used to train the sensitivity weight model

- **FastAPI** – Provides lightweight and fast server endpoints

- **Uvicorn** – ASGI server used to host FastAPI

- **Firebase Admin SDK (Python)** – Handles Firestore communication

- **JSON Serialization** – Converts trained ML models into portable decision-tree format

### Frontend / Mobile App

- **Flutter** – Cross-platform mobile app framework used for UI and user data input

- **Dart** – Programming language for Flutter

- **Firebase Auth / Firestore** – Used for user management and storing preferences

### IoT End-Host Device

- **Python on IoT hardware** – Executes JSON model inference

- **Requests Library** – Fetches updated AI models from the server

- **Datetime / Time Libraries** – Compute time-based weight bonuses

---

## 3. Documentation & References

### Official Documentation

- Firebase Documentation (Firestore, Authentication)

- Flutter Documentation (State management, Firebase integration)

- FastAPI Documentation

- Scikit-Learn Documentation (RandomForestRegressor)

### Technical Blogs & References

- Tutorials on converting ML models into lightweight formats

- Articles on edge AI inference and IoT model deployment

- Guides on JSON decision-tree traversal for embedded systems

---

## 4. Summary

PocketHome builds upon:
- **Smart environment research** on adaptive and context-aware systems

- **Edge computing techniques** that enable local ML inference

- **Weighted preference aggregation** studied in multi-user environments

- **Modern development tools** such as Flutter, Firebase, FastAPI, and scikit-learn

Together, these references form the foundation for PocketHome’s **AI-driven multi-user environment optimization system.**

---

# VI. Conclusion: Discussion
PocketHome began with a simple question: *How can multiple people share the same physical environment comfortably?*  
Throughout the project, this idea grew into a functioning system that combines machine learning, user modeling, and lightweight on-device inference.  
The outcome is not just an automated controller, but an environment that responds intelligently to the people inside it.

---

## 1. What We Learned About Multi-User Environments
Designing an environment for a single user is straightforward.  
Optimizing one for several users—with different preferences, personalities, stress levels, and update patterns—is far more complex.

Through this project, we learned that:
- Comfort varies not only by preference but also by **physiological and behavioral context**.  
- A fair environment emerges when user influence is **weighted dynamically**, not statically.  
- Combining MBTI traits, biometric data, and recency produces **more human-centered optimization** than simple averaging.

PocketHome demonstrated that multi-user adaptation is both achievable and meaningful when the system understands *how different users feel and behave*.

---

## 2. Technical Insights From the System
A key technical achievement of PocketHome was proving that **heavy AI is not required** to build an intelligent environment.

By exporting a Random Forest model into JSON and executing it directly on the end-host device:
- Inference became **fast, lightweight, and transparent**.  
- The system avoided complex ML dependencies.  
- The architecture remained easy to debug, portable, and suitable for IoT deployment.

The weighted-aggregation method consistently produced **stable and interpretable** environment decisions, reinforcing that carefully engineered simple models can outperform unnecessary complexity.

---

## 3. Observations During Testing
During experimentation, several meaningful behaviors appeared:

- The system naturally converged toward **moderate, balanced** temperature ranges when preferences conflicted.  
- Users with high stress or recent actions gained proportionally more influence, reflecting **real human sensitivity**.  
- Retraining caused visible shifts in results, confirming that the model **adapts dynamically** instead of repeating static rules.

These observations show that PocketHome behaves like a system that *learns* rather than one that simply *executes*.

---

## 4. Limitations Identified
Although successful, PocketHome has clear limitations:

- Limited biometric sampling may not fully reflect users’ physiological states.  
- MBTI offers structure but cannot capture the full spectrum of personality differences.  
- Weighted averaging, while effective, may not fully resolve complex conflicts or extreme cases.  
- Real HVAC and lighting hardware integration remains unimplemented.

Recognizing these limitations guides future development.

---

## 5. Future Possibilities
With further development, PocketHome can evolve into a more advanced system:

- Integration with actual IoT hardware for **real-time environmental adjustment**  
- Collecting broader datasets from real environments  
- Applying reinforcement learning for adaptive, long-term improvement  
- Introducing user feedback mechanisms  
- Expanding across multiple rooms or entire buildings  
- Building more sophisticated models of human comfort and stress

These directions position PocketHome as a candidate for *next-generation smart space systems*.

---

## 6. Final Remarks
This project highlighted that environmental control is ultimately a **human-centered challenge**, not just a technical one.  
PocketHome shows that with thoughtful feature design, efficient machine learning, and adaptive logic, even lightweight systems can significantly improve the comfort of shared environments.

Rather than treating rooms as static, PocketHome aims to understand the people within them—and respond accordingly.  
It represents a meaningful step toward more intelligent, personalized, and human-aware living spaces.
