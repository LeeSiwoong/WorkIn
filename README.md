# Workers & Project
Lee Siwoong, Department of Information System, bluewings02@hanyang.ac.kr
</br>
Jang YuanJae, Department of Information System, semxe123@gmail.com   
Park JaeBeom, Department of Information System, tony0604@hanyang.ac.kr
</br>
AI-driven Environmental Optimization Through Multi-User Preference Mediation [PocketHome]

# PocketHome
'PocketHome' is an AI-based automated control system that creates an optimal environment for multiple people at once. 
It works by combining user preferences, personality traits (MBTI), biometric signals, and recorded user behavior from the space. 
Using this information, the system automatically computes shared settings such as temperature, humidity, and brightness. 
The AI's main task is to find a balance that keeps the largest number of people comfortable and satisfied. 

Instead of reinforcement learning, PocketHome uses a lightweight machine-learning model (Random Forest) that learns how long each user's preferences remain relevant based on stress, MBTI, and recent interactions. 
This model is retrained regularly as new data is added, allowing the system to continuously improve without requiring manual adjustments.


[![PocketHome Demo Video](https://img.youtube.com/vi/wpTIaMz8HD0/0.jpg)](https://youtu.be/wpTIaMz8HD0)

▶️ Click image to watch demo video on YouTube.

# I. Introduction

### **Motivation: Why are you doing this?**
In modern shared environments such as offices, classrooms, and co-working spaces, **multiple users often occupy the same physical area while having different preferences** for temperature, humidity, and lighting. However, most existing environmental control systems rely on **a single user’s input** or apply **a uniform setting** to everyone. This frequently leads to discomfort for certain individuals and inefficient operation of HVAC and lighting systems.

Furthermore, users generally do not want to repeatedly adjust environmental settings themselves, and the need for continuous manual control often causes inconvenience and stress. To address these issues, we aim to develop an **AI-driven control system that automatically optimizes the environment based on user preferences, personality traits, and biometric data**.

Additionally, PocketHome adapts to **time-based changes in user sensitivity** and **physiological indicators** such as stress levels and heart-rate variability. For example, users who remain in the same environment for a long time may become less sensitive to small changes, while users with elevated stress or unusual biometric patterns may require more careful environmental adjustments.

PocketHome is more than just an IoT automation system—it is designed to function as an **intelligent decision-making model capable of balancing multiple users' comfort simultaneously**, while dynamically adapting to both personal preferences and biometric signals.


---

### **What do you want to see at the end?**
The final goals of this project are as follows:

1. **Develop an AI-driven environment control system that fairly reflects all users' needs**  
   - Instead of relying on a single fixed satisfaction function, PocketHome learns **user sensitivity (implicit weight)** based on personality traits, biometric conditions, and the recency of user interaction.  
   - The system uses these learned sensitivities to determine a fair and stable environmental setting for the entire group.

2. **Enable continuous improvement through dynamic user data and biometric signals**  
   - The AI model updates its predictions when new user data is stored, including **physiological indicators** (e.g., stress level, heart-rate variability).  
   - The system incorporates **time-based sensitivity decay**, allowing each user’s influence to naturally increase or decrease depending on how long it has been since their last update.  
   - These evolving factors allow PocketHome to adapt continuously as user conditions change.

3. **Create an autonomous environment that minimizes user intervention**  
   - By modeling implicit sensitivity—such as how strongly a user reacts to temperature or humidity differences—the system generates environment settings that reduce the need for manual adjustments.  
   - The model aims to reach **a balanced environmental state** where each user’s influence is proportional to their current sensitivity levels.

4. **Implement a functional client–server prototype connected with real IoT and mobile systems**  
   - The **mobile app** collects user preferences and biometric data into Firebase Firestore.  
   - The **AI server** trains and updates the duration-based sensitivity model, and regularly publishes the latest model to end-host devices.  
   - **End hosts** detect nearby users via BLE, compute the final environment setting using the server-provided model, and apply it to local IoT hardware.

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

This dataset is primarily used by the **AI Model Server**, which:

- Reads user documents from Firestore  
- Computes population-level statistics (e.g., average stress, average HRV)  
- Calculates environment proxies and preference gaps  
- Trains a **duration-based sensitivity model**, which implicitly represents how strongly each user should influence the final environment  
- Exports the trained model as a JSON forest structure for end-host devices

End-host devices then use:

- BLE-detected user IDs to fetch the corresponding documents from Firestore  
- The compiled AI model provided by the server  

to perform a **vectorized full-grid optimization** that searches all feasible temperature, humidity, and brightness combinations, selecting the environment that best fits the sensitivity predictions for the detected users.


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
  "collectedAt": "2025-12-02T19:59:00.000000",
  "stressAvg": 63,
  "heartRateVariation": 12
}
```
- collectedAt : Timestamp in ISO 8601 format, indicating when the biometric data was measured

- stressAvg : Average stress score during the recent sampling window

- heartRateVariation : HRV value used as a proxy for short-term physiological fluctuation
(If biometric data is missing, PocketHome replaces it with the **population average** computed from all users.)

#### **(4) Time-Based Sensitivity Metadata**

Each user document stores a timestamp indicating when their preferences were last updated:

```json
{
  "updatedAt": "202512022210"
}
```
This value is used by the AI model to compute duration-based sensitivity,
which represents how long a user's preference remains influential in the optimization process.

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

If useBodyInfo is false, the bodyMetrics field may be null or omitted entirely.

---

### **4. Dataset Usage in the AI System**

The PocketHome system uses the Firestore dataset in two main components:
1. The **AI Model Server**, which learns how long each user’s preferences remain influential (duration-based implicit weight)
2. The **End-Host Device**, which calculates the shared environmental settings using the server-provided model

---

#### **(1) Weight Model Training (Server-Side)**
The server reads user documents from Firestore and converts them into feature vectors.
Each user contributes the following types of data:
- Environmental preferences  
- Personality traits (full MBTI + decomposed fields)
- Optional biometric indicators
- Time-based metadata (`updatedAt`)
- Gap values between user preferences and the environment proxy

Based on these values, the server generates a **duration label** for each user:
- More recent updates → longer duration  
- High stress or unusual biometric states → longer duration  
- Stale or outdated data → shorter duration  
- Missing biometric data → replaced with population averages

A `RandomForestRegressor` is trained to predict this duration value, which functions as the user’s **implicit sensitivity weight**.

The trained model is exported as JSON and served through the following endpoint:
```bash
GET /weight-model
```

---

#### **(2) Model-Based Environment Calculation (End Host)**
The end host performs three steps:
**1.** Detect user IDs (via BLE)

**2.** Fetch those users' profiles from Firestore (batch queries)

**3.** Download and compile the JSON model into NumPy arrays

Instead of computing a weighted average, the end host performs a full-grid optimization:

- Temperature range: 18.0–28.0°C (0.5 step)

- Humidity: 1–5

- Brightness: 1–10

For every possible combination (~1050 scenarios):

- Feature vectors are constructed

- The Random Forest model predicts duration scores

- Scenario scores are aggregated across all detected users

- The **highest-scoring environment** is selected as the final setting

This ensures that:
- Users with higher predicted duration (implicit weight) influence the environment more

- Recent or stressed users have stronger contributions

- Missing bio data does not harm performance (population averages used)

- MBTI traits and preference gaps meaningfully shape the outcome
---

#### **(3) Continuous Adaptation**
Whenever any user updates:
- environmental preferences

- MBTI information

- biometric data

- or simply as time progresses

PocketHome automatically adapts:
- The AI server retrains periodically (hourly scheduler)

- The duration model updates its learned sensitivities

- End-host devices recalculate the optimal environment

This enables PocketHome to continuously reflect both personal preferences and physiological changes.

---

---

# III. Methodology

PocketHome uses a two-part AI–IoT architecture consisting of a centralized **AI Model Server** and distributed **End-Host controllers**.  
The server performs machine learning and model distribution, while end-host devices compute final environment values using a fast, vectorized optimization algorithm.  
This section describes the complete process—from data ingestion to on-device environment computation and continuous adaptation.

---

## **1. System Architecture Overview**

The PocketHome system operates as a continuous loop:

**Firestore → AI Model Server → Duration Model JSON → End Host → Environment Update**

Overall workflow:

1. Users provide environmental preferences, MBTI traits, and optional biometric data.  
2. Firestore stores all user profiles in a structured format.  
3. The AI Model Server collects all profiles and constructs feature vectors.  
4. A Random Forest model is trained to predict **duration**, which serves as an implicit weight representing how strongly and how long each user's preferences should influence the environment.
5. The trained model is exported as a JSON forest and served through `/weight-model`.  
6. End-host devices download the model, detect active users via BLE, retrieve their Firestore documents, and compute the optimal environment through full-grid simulation.

This division of labor ensures scalable learning while keeping IoT devices lightweight and fast.

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

| Feature Type         | Example Fields                                   |
|----------------------|--------------------------------------------------|
| Personality indicators | mbtiEI, mbtiNS, mbtiTF, mbtiPJ                 |
| Biometric signals      | stressAvg, heartRateVariation                  |
| Preference gaps        | env_proxy − preference (temp, humidity, brightness) |
| Time-based metadata    | hours since updatedAt                          |



These multidimensional features allow the model to represent user **sensitivity**, preference stability, and physiological state in a unified form.

---

## **3. Weight Labeling Logic (Pre-Model Algorithm)**

Before training the machine-learning model, PocketHome computes a **rule-based target weight** for each user.  
This reflects how long each user’s preferences should continue to influence the environment.

Duration factors:

- **Data recency**: recently updated preferences remain influential for longer
- **Stress level**: high stress may extend influence duration
- **Heart-rate variation**: unstable HRV suggests discomfort, increasing duration
- **Missing biometric information**: replaced with population averages
- **Stale profiles**: influence duration naturally decays over time

This duration score becomes the regression label used for training.

---

## **4. Random Forest Weight Model (Core Algorithm)**

The AI Model Server trains a `RandomForestRegressor` to learn how user features map to a **duration value**, which functions as an implicit weight in the optimization process.

### **Why Random Forest?**
- Handles mixed numerical and categorical features (MBTI + biometrics)
- Naturally models non-linear relationships  
- Robust against noise and missing values  
- Light enough to export as JSON for IoT inference  

### **Model Output Format**
The trained model is exported as a lightweight JSON structure containing the forest of decision trees, metadata, and feature definitions:

```json
{
  "feature_names": [...],
  "bio_stats": { "avg_stress": 0, "avg_hrv": 0 },
  "forest": [
    {
      "nodes": [...],
      "thresholds": [...],
      "values": [...]
    }
  ]
}
```

The JSON is served through:

```
GET /weight-model
```

End-host devices repeatedly fetch this model to stay synchronized with the latest learned behavior.

---

## **5. End-Host Environment Optimization Algorithm**

End-host devices compute the final temperature, humidity, and brightness.  
They follow this four-step routine:

1. **Download** the duration-based model JSON  
2. **Detect** active users via BLE and **fetch** only those user profiles from Firestore  
3. **Predict** each user's duration score using the compiled Random Forest model  
4. **Evaluate** all valid environment combinations and select the scenario with the highest total score  

### **Full-Grid Evaluation Process**

```
For each temperature in 18.0–28.0°C (step 0.5):
    For each humidity in 1–5:
        For each brightness in 1–10:
            Compute predicted score for each user
            Sum user scores for this scenario
Select the scenario with the highest total score
```

As a result:

- users with higher predicted duration (implicit weight) influence the outcome more  
- recent updates contribute more strongly  
- missing biometrics are handled via population averages  
- the final environment is chosen from all feasible combinations, not averaged  

This methodology replaces older weighted-average approaches with a more robust, simulation-based optimization algorithm.

---

## **6. Continuous Adaptation Loop**

PocketHome continuously adapts based on:

- new biometric measurements  
- user preference updates  
- personality changes  
- natural time decay applied to `updatedAt`  

Whenever any user state changes:

1. The AI Model Server automatically retrains the **duration model** (hourly scheduler)  
2. End-host devices download the latest duration-based model  
3. Full-grid environmental optimization is recomputed  
4. The environment is updated accordingly  

This loop ensures the system remains sensitive to both physiological signals and preference changes over time.

---

## **7. Code-Level Summary of Core Components**

### **7.1 weight_model_server.py**

Responsibilities:

- Retrieve all user profiles  
- Compute biometric population averages  
- Compute environment proxy and preference gaps  
- Build feature vectors  
- Generate **duration labels** (implicit sensitivity)  
- Train RandomForestRegressor  
- Export model as JSON forest  
- Serve `/weight-model` endpoint  
- Perform automatic hourly retraining  

Pseudo-flow:

```
users = fetch_from_firestore()
bio_stats = compute_bio_averages(users)
env_proxy = compute_environment_proxy(users)
features = encode_features(users, env_proxy, bio_stats)
labels = compute_duration_labels(users)
model = RandomForestRegressor().fit(features, labels)
export_model_as_json(model, bio_stats, feature_names)
```

---

### **7.2 end_host.py**

Responsibilities:

- Detect nearby users via BLE  
- Batch-fetch only detected user profiles from Firestore  
- Download and compile duration model  
- Simulate all environment scenarios (full-grid search)  
- Predict duration scores for each user  
- Select the highest-scoring environment configuration  
- Apply the selected environment  

Pseudo-flow:

```
model = fetch_and_compile_json_model()
active_users = detect_ble_user_ids()
profiles = batch_fetch_firestore(active_users)

scores = []
for scenario in all_environment_combinations:
    score = 0
    for user in profiles:
        pred = model.predict(features_for(user, scenario))
        score += pred
    scores.append(score)

best_env = environment_with_max_score(scores)
apply_environment(best_env)
```

---

## **8. Summary**

PocketHome’s methodology integrates four key ideas:

1. **Sensitivity modeling** using MBTI, biometrics, preference gaps, and time-based recency  
2. **Duration-based weighting** learned through a Random Forest regression model  
3. **Lightweight IoT optimization** using full-grid evaluation rather than weighted averages  
4. **Continuous adaptation** through periodic retraining and BLE-driven user detection  

This design ensures fairness, responsiveness, and interpretability across a multi-user shared environment.


---

# IV. Evaluation & Analysis

This section evaluates how effectively PocketHome optimizes a shared environment for multiple users.  
The analysis is based on (1) optimization output logs, (2) duration-based sensitivity behavior, and (3) retraining and adaptation performance.

---

## **1. Optimization Output Summary**

When PocketHome runs its optimization process, the end-host produces logs such as:

```
▶ [FINAL DECISION] Temp: 23.4°C / Hum: 3 / Light: 5
```

### Interpretation
- **The final environment setting** is selected by evaluating all 1050 valid temperature–humidity–brightness combinations.
- Each scenario is scored using the **duration-based model**, and the scenario with the highest total score is chosen.
- The output remains **stable and consistent** across multiple runs, confirming the reliability of the full-grid optimization method.

This confirms that the optimization objective is functioning as intended.

---

## **2. User Duration Influence Analysis**

The system provides detailed information about each user's influence score:

```
> User[U1] DurationScore: 42.8
> User[U2] DurationScore: 19.4
```

### Interpretation
- The **duration score** reflects MBTI traits, biometric signals (stress / HRV), preference gaps, and recency.
- Higher duration scores indicate users whose preferences should remain influential for longer.
- These scores guide how much each user contributes during scenario evaluation.

Overall, the duration distribution shows that PocketHome **fairly adapts to different user conditions.**

---

## **3. Model Training Performance**

The AI server logs model training status as follows:

```
[Server] Model Trained with 23 users.
```

### Interpretation
- The Random Forest model successfully learns from structured user features (MBTI, biometrics, gaps, recency).
- Retraining occurs **hourly** using APScheduler, ensuring the model stays updated.
- Predicted duration values remain stable across training sessions.

This confirms that the model is **predictable, consistent,** and **adaptable.**

---

## **4. JSON Model Verification**

When the end-host downloads and loads the model:

```
[Client] AI Model Loaded Successfully.
```

### Interpretation
- JSON-based inference replicates the Random Forest’s behavior accurately through NumPy-compiled trees.
- The lightweight JSON format ensures fast inference suitable for IoT devices.
- Model updates propagate reliably whenever the server retrains.

This validates PocketHome’s design choice to use **portable, interpretable model structures.**

---

## **5. Scenario Evaluation**

To evaluate PocketHome in a realistic situation, consider the following:

| User | Temp Preference | Stress | Recent Update | Duration Impact |
| ---- | --------------- | ------ | ------------- | ---------------- |
| U1   | 24°C            | High   | Yes           | Strong Influence |
| U2   | 22°C            | Low    | No            | Weaker Influence |

Optimization Output:

```
FINAL: Temp 23.1°C / Hum 3 / Light 4
```

### Interpretation
- The system correctly gives **stronger influence** to U1 due to stress and recency.
- U2 still contributes, but with weaker influence.
- The final environment reflects **balanced multi-user decision-making** calculated through full-grid scoring.

---

## **6. Feedback → Retraining → Re-Optimization**

Logs during server retraining:

```
[System] Retraining started...
[Server] Model Trained with 24 users.
```

New optimization:

```
▶ [FINAL DECISION] Temp: 23.0°C / Hum: 3 / Light: 4
```

### Interpretation

- The server retrains automatically based on schedule, incorporating new user data.
- Updated duration predictions change the optimization scoring.
- This demonstrates a functional **closed-loop adaptation cycle**.

---

## **7. Summary**

- Full-grid optimization produces **fair and stable** environmental decisions.  
- Duration scores reflect **MBTI traits, biometric data, preference gaps, and recency**.  
- JSON inference provides **fast and accurate** model execution on IoT devices.  
- Hourly retraining improves adaptability and keeps the model responsive.  
- Scenario testing confirms correctness in multi-user environments.

PocketHome effectively achieves **adaptive and user-sensitive environmental optimization.**


---
# V. Related Work

This section summarizes the existing studies, tools, libraries, and documentation referenced during the development of PocketHome.  
The project combines machine learning, IoT device inference, and cloud-based user data management, and therefore relies on several established technologies and prior concepts.

---
## 1. Existing Studies & Concepts

- **Context-Aware Smart Environment Systems**

Research on context-aware computing shows how environmental systems can adapt to user preferences, stress levels, or biometric states.  
PocketHome extends this concept by incorporating MBTI traits, biometric indicators, and a portable duration-based Random Forest model.

- **Edge/On-Device Inference in IoT Systems**

Several studies highlight that IoT environments require lightweight ML models.  
PocketHome applies this principle by exporting a Random Forest into a JSON forest for efficient on-device execution.

- **Multi-User Preference Optimization**

Prior work in shared-environment optimization discusses fairness and multi-user decision balancing.  
PocketHome aligns with these concepts by using **scenario-based scoring** instead of simple averaging, evaluating all feasible environment combinations to ensure fair decision-making.

---

## 2. Tools and Libraries Used

### Backend / AI Model

- **Python 3.10+** – Main backend language  
- **scikit-learn (RandomForestRegressor)** – Used to train the duration-based sensitivity model  
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
- **Datetime / Time Libraries** – Used to interpret recency metadata (updatedAt)

---

## 3. Documentation & References

### Official Documentation

- Firebase Documentation (Firestore, Authentication)  
- Flutter Documentation (State management, Firebase integration)  
- FastAPI Documentation  
- Scikit-Learn Documentation (RandomForestRegressor)

### Technical Blogs & References

- Tutorials on exporting ML models into lightweight formats  
- Articles on edge AI inference and IoT model deployment  
- Guides on JSON decision-tree traversal for embedded systems

---

## 4. Summary

PocketHome builds upon:

- **Smart environment research** on adaptive and context-aware systems  
- **Edge computing techniques** enabling efficient local ML inference  
- **Scenario-based optimization** studied in multi-user environments  
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

- Comfort varies not only by preference but also by **physiological and contextual sensitivity**.  
- A fair environment emerges when user influence is **dynamic rather than static**, adapting to real-time recency and biometric factors.  
- Combining MBTI traits, biometric data, preference gaps, and time-based recency produces **more human-centered optimization** than simple averaging.

PocketHome demonstrated that multi-user adaptation is both achievable and meaningful when the system understands *how different users respond to their environment*.

---

## 2. Technical Insights From the System

A key technical achievement of PocketHome was proving that **heavy AI is not required** to build an intelligent environment.

By exporting a Random Forest model into JSON and executing it directly on the end-host device:

- Inference became **fast, lightweight, and transparent**.  
- The system avoided complex ML dependencies.  
- The architecture remained easy to debug, portable, and suitable for IoT deployment.

PocketHome’s **full-grid scenario evaluation** consistently produced **stable and interpretable** environment decisions, demonstrating that carefully engineered lightweight models can outperform unnecessary complexity.

---

## 3. Observations During Testing

During experimentation, several meaningful behaviors appeared:

- The system naturally converged toward **moderate, balanced** temperature ranges when preferences conflicted.  
- Users with high stress or recent updates received proportionally higher influence through the **duration model**, reflecting realistic human sensitivity.  
- Retraining caused visible shifts in results, confirming that the model **adapts dynamically** instead of repeating static rules.

These observations show that PocketHome behaves like a system that *learns* rather than one that simply *executes*.

---

## 4. Limitations Identified

Although successful, PocketHome has clear limitations:

- Limited biometric sampling may not fully reflect users’ physiological states.  
- MBTI provides structure but cannot capture the full spectrum of personality differences.  
- Full-grid optimization, while effective, may become computationally expensive for much larger parameter spaces.  
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
