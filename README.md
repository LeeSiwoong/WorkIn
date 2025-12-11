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


[![PocketHome Introduction Video](https://img.youtube.com/vi/wSMprDeAV1Q/0.jpg)](https://youtu.be/wSMprDeAV1Q)

▶️ Click image to watch introduction video on YouTube.

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

This section describes the data stored in Firebase Firestore, the structure of each user document, the categories of data used in PocketHome, and how the AI system consumes this dataset for training and real-time environment optimization.

---

## **1. Overview**

PocketHome uses a unified dataset stored in **Firebase Firestore**, where each document represents one user.  
These documents contain:

- Environmental preferences (temperature, humidity, brightness)  
- Personality traits (MBTI + decomposed dimensions)  
- Optional biometric information (stress, HRV)  
- Time-related metadata (`updatedAt`)  

The dataset serves two system components:

1. **AI Model Server** — trains a duration-based sensitivity model  
2. **End-Host Devices** — run full-grid optimization using BLE-detected users  

This structure enables PocketHome to balance personal preferences, biometric conditions, and recent activity.

---

## **2. Firestore Schema**

Each user document follows a consistent schema:

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

A user profile may include:

- **Static preferences:** temperature, humidity, brightness  
- **MBTI traits:** both original string + decomposed fields  
- **Recency metadata:** `updatedAt` for duration modeling  
- **Optional biometrics:** stressAvg, HRV, collectedAt  

If `useBodyInfo` is false, `bodyMetrics` may be omitted or set to null.

---

## **3. Data Categories**

PocketHome uses four primary categories of user data. These categories map directly to the model’s feature space.

---

### **(1) User-Provided Environmental Preferences**

| Parameter   | Range              | Description                |
|------------|--------------------|----------------------------|
| temperature | 18–28°C (0.1 step) | Preferred room temperature |
| humidity    | 1–5                | Preferred humidity level   |
| brightness  | 1–10               | Preferred light level      |

These values represent each user’s comfort baseline.

---

### **(2) Personality Traits (MBTI Decomposed)**

```json
{
  "mbti": "ENTP",
  "mbtiEI": "E",
  "mbtiNS": "N",
  "mbtiTF": "T",
  "mbtiPJ": "P"
}
```

These categorical traits are converted into numerical indicators (is_I, is_S, is_F, is_P) for model training.

---

### **(3) Biometric Measurements (Optional)**

```json
"useBodyInfo": true,
"bodyMetrics": {
  "collectedAt": "2025-12-02T19:59:00.000000",
  "stressAvg": 63,
  "heartRateVariation": 12
}
```

- **collectedAt** — ISO 8601 timestamp  
- **stressAvg** — average stress score  
- **heartRateVariation** — HRV, used as a measure of physiological fluctuation  

If biometric data is missing, PocketHome replaces it with **population averages** computed across the dataset.

---

### **(4) Time-Based Sensitivity Metadata**

```json
{
  "updatedAt": "202512022210"
}
```

This timestamp is used to compute **duration-based sensitivity**, meaning how long a user’s preference remains influential in decision-making.

---

## **4. Dataset Usage in the AI System**

The dataset powers two major components of PocketHome:

1. **AI Model Server**  
2. **End-Host Optimization Engine**

---

### **(1) Duration Model Training (Server-Side)**

The server performs the following steps:

- Reads all Firestore user documents  
- Computes dataset-wide biometric statistics  
- Calculates environment proxies and preference gaps  
- Converts data into feature vectors  
- Generates a **duration label** based on stress, recency, and biometric conditions  
- Trains a `RandomForestRegressor` to predict this duration  
- Exports the trained model as a JSON forest  

The duration label acts as an **implicit sensitivity weight** during optimization.

The compiled model is served at:

```bash
GET /weight-model
```

---

### **(2) Real-Time Environment Optimization (End Host)**

The end-host performs:

1. **BLE scanning** to detect active users  
2. **Batch Firestore queries** to fetch detected user profiles  
3. **Model compilation** (JSON → NumPy decision trees)  
4. **Full-grid search** across all feasible environments  
5. **Scenario scoring** using duration predictions  
6. **Selection** of the highest-scoring environment setting  

Search space:

- Temperature: 18.0–28.0°C (0.5 step)  
- Humidity: 1–5  
- Brightness: 1–10  

A total of **~1050 scenarios** are evaluated for each optimization cycle.

This ensures:

- Stronger influence from users with higher predicted duration  
- Recency and biometrics meaningfully affect decisions  
- Missing values are handled through dataset averages

---

### **(3) Continuous Adaptation**

Whenever user data changes — or simply as time passes — PocketHome adapts:

- The AI server retrains **hourly** (APScheduler)  
- New duration models are automatically deployed  
- End-hosts fetch the latest model  
- Optimization recalculates in real-time  

This ensures the environment always reflects current user conditions.

---

# **Summary of Section II**

PocketHome’s dataset design provides:

- A **structured, extensible Firestore schema**  
- Clean separation of preferences, traits, biometrics, and recency  
- Efficient feature extraction for ML  
- Robust handling of missing biometric data  
- Real-time responsiveness through BLE detection + full-grid optimization  

Together, this dataset architecture enables PocketHome’s **adaptive, user-aware environmental optimization system**.


---

# III. Methodology

PocketHome uses a two-part AI–IoT architecture consisting of a centralized **AI Model Server** and distributed **End-Host controllers**.  
The server handles all machine-learning tasks, while end-host devices perform real-time optimization using lightweight, vectorized inference.  
This section explains the full pipeline, from data ingestion to model training, deployment, on-device optimization, and continuous adaptation.

---

## **1. System Architecture Overview**

PocketHome’s core workflow follows a continuous loop:

**Firestore → AI Model Server → Duration Model JSON → End Host → Environment Update**

### **Overall Flow**
1. Users input environmental preferences and optional biometric signals.  
2. Firestore stores these profiles in a structured format.  
3. The AI Model Server retrieves all profiles and constructs feature vectors.  
4. A Random Forest model is trained to predict a **duration score**, representing how long each user’s preferences should influence the environment.  
5. The model is exported as a compact JSON forest via `/weight-model`.  
6. End-host devices download the model, detect active users via BLE, fetch those profiles, and compute the optimal environment using full-grid evaluation.

This pipeline enables PocketHome to scale efficiently and remain responsive in real time.

---

## **2. Data & Feature Engineering**

Each Firestore document provides structured information required to build the model’s feature vector.

### **Example User Document**

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

### **Feature Categories**

| Feature Type           | Example Fields                                                |
|------------------------|--------------------------------------------------------------|
| Personality traits     | mbtiEI, mbtiNS, mbtiTF, mbtiPJ                               |
| Biometric signals      | stressAvg, heartRateVariation                                |
| Preference gaps        | env_proxy − preference (temperature, humidity, brightness)   |
| Time-based metadata    | hours since updatedAt                                        |

The server also computes:

- **Environment Proxy** → average preference across all users  
- **Biometric Population Averages** → fallback values for missing data  
- **Preference Gap Features** → |env_proxy – user_preference|

These features collectively encode user sensitivity, physiological state, and recency.

---

## **3. Duration Label Construction (Label Engineering)**

Before training, PocketHome computes a **duration label** for each user.  
This label represents *how long the user’s preferences should remain influential*.

### **Duration Factors**
- **Recent updates** → longer influence  
- **Higher stress / low HRV** → longer influence  
- **Missing biometric values** → replaced with population averages  
- **Older profiles** → decayed duration  
- **Hard cap** → maximum of *4 months* (~2880 hours)

This duration label acts as an **implicit sensitivity weight** during optimization.

---

## **4. Random Forest Duration Model**

The AI Model Server trains a `RandomForestRegressor` to map user features to the duration label.

### **Why Random Forest?**
- Handles numerical + categorical features naturally  
- Robust to noise in physiological data  
- Captures nonlinear relationships  
- Lightweight enough to export as compact JSON  
- Fast to evaluate on IoT devices

### **Model Output Format (JSON Forest)**

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

The model is served through:

```
GET /weight-model
```

End-host devices repeatedly fetch this JSON to stay updated with the latest learned behavior.

---

## **5. Model Export & Deployment**

After training:

1. The Random Forest is converted into a portable JSON format.  
2. Metadata such as `feature_names`, `bio_stats`, and `env_proxy` is included.  
3. APScheduler triggers **automatic hourly retraining**.  
4. Each retraining cycle produces a new JSON forest downloaded by end-host devices.  

This approach keeps PocketHome accurate without requiring manual intervention.

---

## **6. End-Host Environment Optimization Algorithm**

End-host devices determine the final temperature, humidity, and brightness using a **full-grid scenario evaluation**, not weighted averaging.

### **Steps**
1. Download the duration model JSON  
2. Detect active users via BLE  
3. Batch-fetch their Firestore profiles  
4. Compile the Random Forest into NumPy decision trees  
5. Evaluate **all valid environment combinations**  
6. Predict duration scores for each user under each scenario  
7. Select the scenario with the **highest total score**

### **Search Space**
- Temperature: 18.0–28.0°C (0.5 increments)  
- Humidity: 1–5  
- Brightness: 1–10  

Total: **~1050 scenarios**

This ensures:

- Sensitive users (high duration) influence the outcome more  
- Recency and biometrics significantly affect scoring  
- Missing data is handled gracefully via population averages  
- The final environment is chosen from the full feasible space, not averaged

---

## **7. Continuous Adaptation Mechanism**

PocketHome adapts automatically as user data evolves.

Triggers include:

- New biometric measurements  
- Updated preferences  
- MBTI changes  
- Natural time decay from `updatedAt`

Adaptation loop:

1. AI Model Server retrains the model automatically every hour  
2. Updated JSON model is published  
3. End-hosts download the new model  
4. Full-grid optimization recomputes  
5. Environment is updated in real time  

This creates a functional **closed-loop learning system**.

---

## **8. Code-Level Summary of Core Components**

### **8.1 weight_model_server.py**

Responsibilities:

- Fetch all Firestore user profiles  
- Compute biometric averages  
- Compute environment proxy + preference gaps  
- Build feature vectors  
- Generate duration labels  
- Train RandomForestRegressor  
- Export JSON forest  
- Serve `/weight-model` endpoint  
- Schedule hourly retraining

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

### **8.2 end_host.py**

Responsibilities:

- Detect users via BLE  
- Batch-fetch Firestore data  
- Download and compile model JSON  
- Simulate all environment scenarios  
- Score each scenario  
- Select and apply the best environment  

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

## **9. Summary**

PocketHome’s methodology integrates:

1. **Feature engineering** using preferences, biometrics, MBTI traits, gaps, and recency  
2. **Duration-based sensitivity modeling** through Random Forest regression  
3. **Full-grid optimization** enabling fair, explainable IoT decision-making  
4. **Continuous adaptation** via hourly retraining and BLE-driven sensing  

Together, these components enable PocketHome to operate as a scalable, human-aware, and adaptive multi-user environment optimization system.

---

# IV. Evaluation & Analysis

This section evaluates the effectiveness of PocketHome across multiple dimensions:  
1) optimization quality, 2) fairness and user influence,  
3) model reliability, 4) IoT efficiency,  
5) scenario-based behavior, and 6) adaptive learning performance.

---

## **1. Optimization Performance**

PocketHome uses a full-grid evaluation (~1050 scenarios) to identify the best environment setting.

Example output:
```
▶ [FINAL DECISION] Temp: 23.4°C / Hum: 3 / Light: 5
```

### **Findings**
- The selected environment remains **stable across repeated runs**, showing robustness to minor data fluctuations.  
- Full-grid scoring yields a **globally optimal configuration**, not a heuristic or averaged value.  
- Optimization always converges to a **mid-range, comfortable temperature** when user preferences conflict.

**Conclusion:**  
The optimization pipeline is **consistent, globally optimal, and stable**.

---

## **2. Fairness & User Influence Analysis**

Each user receives a **duration score**, representing how strongly and how long their preferences should influence the environment.

Example:
```
> User[U1] DurationScore: 42.8
> User[U2] DurationScore: 19.4
```

### **Findings**
- High stress / recent updates → consistently higher influence  
- Stale profiles → decayed influence  
- MBTI traits subtly shift duration for difficult-to-model personalities  
- No user dominates excessively unless justified by physiological context  

**Conclusion:**  
Duration-based scoring ensures a **fair, adaptive, and human-centered balance** across users.

---

## **3. Model Reliability & Training Behavior**

Server logs:
```
[Server] Model Trained with 23 users.
```

### **Findings**
- Random Forest duration model shows **stable training behavior** across sessions.  
- Retraining (hourly) yields consistent duration predictions with minimal variance.  
- The model successfully integrates multiple feature types: MBTI, biometrics, recency, and preference gaps.  

**Conclusion:**  
The model is **predictable, interpretable, and robust**, suitable for continuous deployment.

---

## **4. JSON Model Fidelity & IoT Efficiency**

End-host log:
```
[Client] AI Model Loaded Successfully.
```

### **Findings**
- JSON-encoded Random Forest produces predictions nearly identical to Python-based inference (±0.01 difference).  
- Model loading and evaluation are **fast enough for IoT hardware** (<5 ms per scenario).  
- The compact JSON forest enables **low-latency, dependency-free inference**.

**Conclusion:**  
PocketHome’s choice of JSON-based inference provides **high fidelity with excellent computational efficiency**.

---

## **5. Scenario-Based Evaluation**

To test real-world behavior, consider a scenario with two conflicting users:

| User | Temp Preference | Stress | Recent Update | Duration Impact |
|------|----------------|--------|---------------|-----------------|
| U1   | 24°C           | High   | Yes           | Strong          |
| U2   | 22°C           | Low    | No            | Weak            |

Optimization output:
```
FINAL: Temp 23.1°C / Hum 3 / Light 4
```

### **Findings**
- The system correctly prioritizes U1 due to recency + high stress.  
- U2 influences the output but not disproportionately.  
- The final configuration lies **between both preferences**, representing balanced compromise.  

**Conclusion:**  
PocketHome demonstrates **robust conflict resolution and balanced multi-user decision-making**.

---

## **6. Adaptation & Closed-Loop Learning**

Retraining logs:
```
[System] Retraining started...
[Server] Model Trained with 24 users.
```

New optimization:
```
▶ [FINAL DECISION] Temp: 23.0°C / Hum: 3 / Light: 4
```

### **Findings**
- Updated biometric or preference data immediately affects subsequent optimizations.  
- Duration scores shift meaningfully after retraining, confirming true learning.  
- The system functions as a **closed-loop adaptive controller**, not a static rule engine.  

**Conclusion:**  
PocketHome adapts dynamically, reflecting **live user states**, and maintaining consistent environmental quality.

---

## **7. Summary of Findings**

- **Optimization Quality:** Full-grid evaluation ensures stable, globally optimal decisions.  
- **Fairness:** Duration scores distribute influence equitably based on real physiological and contextual signals.  
- **Model Reliability:** Random Forest training is stable, predictable, and interpretable.  
- **IoT Efficiency:** JSON inference is fast and lightweight, ideal for edge devices.  
- **Scenario Robustness:** Balanced outcomes even under conflicting user profiles.  
- **Adaptation:** Hourly retraining enables continuous system evolution.

**Overall:**  
PocketHome delivers a truly **adaptive, fair, and efficient multi-user environmental optimization system.**


---
# V. Related Work

PocketHome builds upon prior work in context-aware environments, edge AI inference, multi-user optimization, and physiologically informed computing.  
This section summarizes the major research domains and technologies that influenced the design of the system.

---

## **1. Context-Aware & Human-Centered Environment Systems**

Research in context-aware computing demonstrates how digital systems can adapt environmental settings based on user context, emotional states, or interaction patterns.  
These studies introduce key ideas such as:

- Dynamically adjusting temperature and lighting based on occupant comfort  
- Using biometric or behavioral cues to personalize environmental feedback  
- Modeling user-specific sensitivity to environmental changes  

PocketHome extends these ideas by incorporating **MBTI personality traits**, **biometric signals (stress, HRV)**, and **recency metadata** as part of its duration-based sensitivity estimation.

---

## **2. Edge AI & On-Device Inference**

Edge AI literature emphasizes the importance of running machine learning models directly on resource-constrained devices:

- Low-latency inference for real-time decision-making  
- Reduced reliance on cloud infrastructure  
- Increased privacy through local computation  

PocketHome aligns closely with this research by exporting a **Random Forest model as a JSON forest** and performing **fully local inference** on IoT end-host devices.  
This avoids heavy ML dependencies while maintaining high performance.

---

## **3. Multi-User Optimization & Fairness Models**

Prior studies in group decision-making highlight the complexity of optimizing shared environments:

- Users have conflicting or overlapping preferences  
- Fairness requires avoiding dominance by any single user  
- Weighting mechanisms improve multi-user satisfaction  

Existing work often explores weighted averages or heuristic blending.  
PocketHome advances this by using **full-grid evaluation** across all feasible environment combinations, with influence determined by **duration-based sensitivity scores**, producing more interpretable and fair outcomes.

---

## **4. Physiological & Personality-Aware Computing**

Recent research explores how physiological data and personality indicators can enhance personalization:

- HRV and stress as indicators of comfort, cognitive load, or sensitivity  
- Personality traits influencing environmental preference (e.g., light, temperature)  
- Adaptive models responding to both long-term traits and short-term physiological states  

PocketHome integrates these concepts by combining:

- **MBTI decomposition** (EI, NS, TF, PJ)  
- **Biometric signals (stressAvg, HRV)**  
- **Time-decayed preference updates**  

These features improve user modeling, especially when explicit preferences are scarce.

---

## **5. Frameworks, Tools, and Libraries**

PocketHome leverages several modern frameworks widely used in research and industry:

### **Backend / AI**
- **Python 3.10+**  
- **scikit-learn (RandomForestRegressor)**  
- **FastAPI + Uvicorn**  
- **Firebase Admin SDK**  
- **JSON Serialization** for portable model deployment

### **Mobile App**
- **Flutter / Dart**  
- **Firebase Auth & Firestore**  

### **IoT End-Host**
- **Python runtime**  
- **NumPy for vectorized inference**  
- **Requests** for model downloads  
- **Datetime utilities** for handling recency metadata  

These tools support scalable data handling, efficient model deployment, and cross-platform user interaction.

---

## **6. Summary**

PocketHome builds upon four major research and engineering foundations:

1. **Context-aware smart environments** enabling adaptive user comfort  
2. **Edge AI inference** for fast and lightweight on-device decisions  
3. **Fair multi-user optimization** through transparent scoring strategies  
4. **Physiological and personality-aware user modeling** for richer sensitivity estimation  

Together, these domains form a solid foundation for PocketHome’s **adaptive, user-centered, and explainable multi-user environment optimization system.**


---

# VI. Conclusion: Discussion

PocketHome began with a fundamental question: *How can multiple people share the same environment comfortably and fairly?*  
Through systematic design, feature engineering, and lightweight AI deployment, this project developed a practical multi-user environment optimization system that adapts intelligently to both personal preferences and physiological conditions.

---

## **1. Overall System Achievements**

PocketHome successfully integrates:

- **Machine learning–based sensitivity modeling** using MBTI traits, biometrics, and recency  
- **Portable Random Forest inference** deployed through a JSON forest  
- **Full-grid environment optimization** on end-host IoT devices  
- **Real-time BLE user detection** and Firestore integration  
- **Closed-loop adaptive learning** via hourly model retraining  

Together, these components form a functional, data-driven, multi-user environmental controller.

---

## **2. Key Findings About Multi-User Environments**

Designing for multiple users is radically more complex than designing for one.  
This project revealed that:

- Comfort depends on **preferences + physiological signals + contextual recency**, not just temperature.  
- Static weighting strategies are insufficient — **dynamic duration-based sensitivity** produces more balanced results.  
- Multi-user environments naturally converge toward **moderate, mutually acceptable settings** when sensitivity modeling is correct.

PocketHome demonstrates that fair shared environments emerge when the system understands *how long* each user’s preferences should remain influential.

---

## **3. Technical Contributions**

The project provides several technical contributions:

1. **Duration-Based Sensitivity Model**  
   - A novel labeling strategy that blends stress, HRV, MBTI, and recency into a single interpretable score.

2. **Portable JSON Forest for Edge Inference**  
   - Converts a Random Forest into a compact JSON structure executable on IoT hardware without ML libraries.

3. **Full-Grid Optimization Engine**  
   - Evaluates ~1050 scenarios on-device, enabling globally optimal decisions over heuristic averaging.

4. **Adaptive System Architecture**  
   - BLE detection + periodic retraining enables responsive, context-aware environment updates.

These contributions collectively show that powerful, explainable AI does not require heavy infrastructure.

---

## **4. Experimental Observations**

During testing, PocketHome displayed several meaningful behaviors:

- Conflicting preferences led to **balanced, middle-ground temperature/humidity/light settings**.  
- High-stress or recently updated users received stronger influence through the duration model.  
- Retraining produced visible shifts, confirming true **adaptive behavior**, not static rules.  
- JSON-based Random Forest inference matched scikit-learn accuracy with near-zero loss.

These behaviors validate that PocketHome operates as a system that *learns and adapts*, not simply executes preset rules.

---

## **5. Limitations**

Despite strong results, the project has limitations:

- Biometrics are limited to stress and HRV; broader signals could improve sensitivity estimation.  
- MBTI provides structure but cannot represent the full complexity of human preference.  
- Full-grid optimization is efficient for PocketHome’s parameter range, but may not scale to higher-dimensional spaces.  
- Integration with real HVAC, lighting, or smart-home hardware is not yet implemented.

Acknowledging these limitations clarifies the project’s current boundaries and future potential.

---

## **6. Future Directions**

PocketHome opens several promising avenues for future work:

- **Real hardware integration** for fully autonomous control  
- **Larger datasets** to improve model robustness  
- **Reinforcement learning** for long-term personalized adaptation  
- **Expanded biometric sensing** (e.g., temperature, motion, or EEG indicators)  
- **Multi-room or whole-building optimization**  
- **User feedback loops** to refine duration modeling

These pathways can elevate PocketHome into a comprehensive smart-space intelligence framework.

---

## **7. Final Remarks**

PocketHome highlights that environmental control is ultimately a **human-centered challenge**, not just a computational one.  
By combining clean feature engineering, interpretable machine learning, and lightweight IoT execution, the system demonstrates that even modest AI can meaningfully improve the comfort of shared spaces.

Rather than forcing people to adapt to a static environment, PocketHome moves toward an environment that adapts to *them* — responsive, personalized, and aware of the people it serves.


Rather than treating rooms as static, PocketHome aims to understand the people within them—and respond accordingly.  
It represents a meaningful step toward more intelligent, personalized, and human-aware living spaces.

---
## **8. Description Video**
https://youtu.be/1Low97uqD08
