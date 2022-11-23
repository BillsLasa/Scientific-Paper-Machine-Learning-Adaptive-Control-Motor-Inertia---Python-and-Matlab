clc, clearvars, close all

syms s t w(t)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% MODELO DEL MOTOR DC SIN CARGA %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEFINIMOS LAS CONSTANTES DEL MOTOR DC
Va = 220;        % Voltaje de Alimentación - Voltios (V)
R = 2.2;         % Resistencia de Armadura - Ohmios(Ohm)
L = 6.3e-3;      % Inductancia de Armadura - Henrios(H)
km = 1.78;       % Relacion Torque/Corriente - (Nm/A)
ka = km;         % Relacion Voltaje/Velocidad - (V.s/rad)
B = 0.015;       % Coeficiente de Fricción Viscosa - (Nm.s)
J0 = 0.0236;     % Inercia del Motor Sin Carga - (Kg.m^2)

wmax = 122;
G = wmax;

%DEFINIMOS LAS MATRICES COEFICIENTES DE LAS ECUACIONES DE ESPACIO-ESTADO
Ap = [-R/L -(G*ka)/L; km/(G*J0) -B/J0];
Bp = [Va/L; 0];
Cp = [0 1];
Dp = 0;

%CREAMOS EL SISTEMA EN BASE A LAS MATRICES
planta = ss(Ap,Bp,Cp,Dp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% DISEÑO DEL CONTROLADOR %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEFINIMOS LOS PARÁMETROS DE RENDIMIENTO DE LA RESPUESTA DESEADA
ts = 0.03;

%HALLAMOS LOS POLOS NECESARIOS PARA ALCANZAR LOS REQUERIMIENTOS
sigma = 3/ts;

P1 = -sigma;
P2 = -40*sigma;

polos = [P1 P2];

%HALLAMOS LA MATRIZ K DE LA LEY DE CONTROL MEDIANTE FÓRMULA DE ACKER
K = acker(Ap,Bp,polos);

%DEFINIMOS LAS NUEVAS MATRICES DE LAS NUEVAS ECUACIONES DE ESTADO PARA EL
%VOLTAJE DE SALIDA, QUÉ ES LA SEGUNDA VARIABLE DE ESTADO
Am = Ap-Bp*K;
Bm = Bp*K(2);
Cm = Cp;
Dm = Dp;

%CREAMOS EL NUEVO SISTEMA QUE ES LA PLANTA CONTROLADA
planta_controlada = ss(Am,Bm,Cm,Dm);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% SIMULACIÓN Y OBTENCIÓN DE DATOS DE REFERENCIA %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%SIMULAR EL MOTOR EN SIMULINK Y LIMPIAR LAS MATRICES DE TIEMPO Y VELOCIDAD
sim('E1S_Data_Modelo_Referencia')           % Simular el archivo de Simulink
clear t_modelo w_modelo

%OBTENER LOS DATOS DE TIEMPO Y VELOCIDADES CON INERCIA SIN CARGA
t_modelo = ans.datos_modelo.Time;               % Obtener la matriz de tiempos de la simulación
w_modelo = ans.datos_modelo.Data(:,2);          % Obtener la matriz de velocidades del sistema controlado
w_planta = ans.datos_modelo.Data(:,1);          % Obtener la matriz de velocidades de la planta

%OBTENER LA VELOCIDAD EN TIEMPO ESTACIONARIO
w_est = w_planta(end);
w_estacionario = w_modelo(end);                 % Obtener la velocidad en tiempo estacionario de la simulación

%INDICE DE LA VELOCIDAD QUE ESTÁ AL 95%, PERO EL ÍNDICE MÁS CERCANO AL FINAL
indices_t = find(w_modelo >= (0.949*w_estacionario) & (w_modelo <= (0.951*w_estacionario)));
indice_t = max(indices_t);

%OBTENER EL TIEMPO DE ESTABLECIMIENTO
ta_modelo = t_modelo(indice_t);

%GUARDAR TIEMPO DE ESTABLECIMIENTO Y VELOCIDAD EN ESTADO ESTACIONARIO
parametros_modelo = [w_est ta_modelo];
%save('Parametros_modelo.mat','parametros_modelo')

%load('Parametros_modelo.mat')
