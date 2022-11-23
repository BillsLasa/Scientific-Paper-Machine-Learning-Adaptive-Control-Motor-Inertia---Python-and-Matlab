# (Scientific Paper) Machine Learning Adaptive Control Motor Inertia - Python and Matlab 

This repository stores all the codes used for the scientific paper entitled **"Adaptive Pole Positioning Control using Machine Learning for DC Motor with Variable Inertia"**. It consists of python and matlab codes that were used to simulate 2000 different DC motors, obtain the necessary data and train 4 supervised machine learning models for regression, with the objective of creating a control element that regulates the speed of the motor when inertia changes. For more details, please visit my scientific paper: https://doi.org/10.37811/cl_rcm.v6i5.3152

## Author 👤
**Luis Ángel Sánchez Aguilar**

* [LinkedIn](https://www.linkedin.com/in/sanchezluismachinelearning/)

## Folders description 📁

* **[Etapa1-Modelo_Referencia]**: This folder contains the Matlab code that simulates a DC motor as a reference model to which the motor should be adapted when the inertia varies. The folder stores the matlab code and the simulink file with the mathematical model of the motor.

* **[Etapa2-Obtencion_Dataset]**: This folder contains the Matlab code that obtains data from 2000 mathematical models of DC motors built in simulink that differ by a small variation in inertia. 

* **[Etapa3-Entrenamiento_Validacion]**: This folder contains the Python code documented through Google Colab notebooks where 4 machine learning models are trained and validated. Specifically the algorithms are: polynomial regression, decision tree, random forest and support vector machine.

* **[Etapa4-Comparacion_Resultados]**: This folder contains the Python code documented through Google Colab notebooks where the validation behavior of the 4 machine learning models is graphically compared.

* **[Etapa5-Implementacion]**: This folder contains an application made in Matlab AppDesigner that shows the behavior of the machine learning models under the current inertia of the DC motor.

## How to cite this scientific paper?
Sánchez Aguilar, L. Ángel. (2022). Control por posicionamiento de polos adaptivo usando machine learning para motor DC con inercia variable. Ciencia Latina Revista Científica Multidisciplinar, 6(5), 925-943. https://doi.org/10.37811/cl_rcm.v6i5.3152

## Hiring 🤝🏿
If you wish to hire me, please contact me at the following e-mail address: luislasabills@gmail.com
