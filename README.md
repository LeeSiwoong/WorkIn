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
```
{
  "mbti": "INTP",
  "temperature": 24.0,
  "humidity": 3,
  "brightness": 5
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

The final output:
```
{
  "temp": 22.5,
  "hum": 3,
  "light": 6
}
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
