clc, clearvars, close all
rng('default') %Semilla de Random

syms s t
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% MODELO DEL MOTOR DC %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEFINIMOS LAS CONSTANTES DEL MOTOR DC
orden = 2;          % Orden del sistema

Va = 220;           % Voltaje de Alimentación - Voltios (V)
R = 2.2;            % Resistencia de Armadura - Ohmios(Ohm)
L = 6.3e-3;         % Inductancia de Armadura - Henrios(H)
km = 1.78;          % Relacion Torque/Corriente - (Nm/A)
ka = km;            % Relacion Voltaje/Velocidad - (V.s/rad)
B = 0.015;          % Coeficiente de Fricción Viscosa - (Nm.s)
J0 = 0.0236;        % Inercia del Motor Sin Carga - (Kg.m^2)
Jminimo = J0*1.005; % Inercia del Motor con Carga Mínima - (Kg.m^2)
Jmaximo = 5*J0;     % Inercia del Motor Con Carga Máxima - (Kg.m^2)

wmax = 122;
G = wmax;

%DEFINIMOS LAS VARIABLES DEL MOTOR DC (INERCIA DE MASA DEL MOTOR Y CARGA)
n_datos = 2000;                           % Número de Datos Deseados de Inercia
J = linspace(Jminimo,Jmaximo,n_datos);    % N-Datos (n_datos) De Inercia Normalmente Aleatorio

%CARGAR LAS CARACTERÍSTICAS DEL MODELO DE REFERENCIA
load('Parametros_modelo.mat')
w_est_modelo = parametros_modelo(1);
ta_modelo = parametros_modelo(2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% OBTENCIÓN DE DATOS %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%BUCLE PARA OBTENER EL TIEMPO DE ESTABLECIMIENTO Y MÁXIMO SOBREPICO DE LA VELOCIDAD DEL MOTOR PARA CADA INERCIA
for i = 1:n_datos
    disp(['Hallando datos para la Inercia: ', num2str(i), '/', num2str(n_datos)])
    J_actual = J(i);        % Inercia de Masa del Motor
    
    %DEFINIMOS LAS MATRICES COEFICIENTES DE LAS ECUACIONES DE ESPACIO-ESTADO DE CADA INERCIA
    Ap_i = [-R/L -(G*ka)/L; km/(G*J_actual) -B/J_actual];
    Bp_i = [Va/L; 0]; 
    Cp_i = [0 1];
    Dp_i = 0;
    
    %DEFINIMOS LOS PARÁMETROS DE RENDIMIENTO DE LA RESPUESTA DESEADA
    ts = 0.03;
    %Mp = 0.1;

    error_ts = 0.1;
    liminf_ts = (1-error_ts)*ta_modelo;
    limsup_ts = (1+error_ts)*ta_modelo;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% DISEÑO DEL CONTROLADOR %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    peligro = 0;
    ta_alcanzado = 0;
    ta_actual = 0;
    while(ta_alcanzado == 0)
        %HALLAMOS LOS POLOS NECESARIOS PARA ALCANZAR LOS REQUERIMIENTOS
        sigma = 3/ts;

        P1 = -sigma;
        P2 = -40*sigma;

        polos = [P1 P2];

        %HALLAMOS LA MATRIZ K DE LA LEY DE CONTROL MEDIANTE FÓRMULA DE ACKER
        K = acker(Ap_i,Bp_i,polos);
        
        %SIMULAR EL MOTOR EN SIMULINK Y LIMPIAR LAS MATRICES DE TIEMPO Y VELOCIDAD
        sim('E2S_Data_Obtencion_Dataset')    % Simular el archivo de Simulink
        clear t_pp w_pp
              
        %OBTENER LOS DATOS DE TIEMPO Y VELOCIDADES CON LA INERCIA ACTUAL Y TS ACTUAL
        t_pp = ans.datos_entrenamiento.Time;            % Obtener la matriz de tiempos de la simulación
        w_planta = ans.datos_entrenamiento.Data(:,1);   % Obtener la matriz de velocidades de la planta
        w_pp = ans.datos_entrenamiento.Data(:,2);       % Obtener la matriz de velocidades de la simulación

        %OBTENER LA VELOCIDAD EN TIEMPO ESTACIONARIO
        w_est = w_pp(end);    % Obtener la velocidad en tiempo estacionario de la simulación
        
        %INDICE DE LA VELOCIDAD QUE ESTÁ AL 95%, PERO EL ÍNDICE MÁS CERCANO AL FINAL
        indices_t = find(((w_pp >= (0.948*w_est)) & (w_pp <= (0.952*w_est))) | ((w_pp >= (1.048*w_est)) & (w_pp <= (1.052*w_est))));
        indice_t = max(indices_t);
        
        %OBTENER EL TIEMPO DE ASENTAMIENTO DE LA PLANTA CONTROLADA
        ta_previo = ta_actual;
        ta_actual = t_pp(indice_t);
        
        %INDICE DE LA VELOCIDAD QUE ESTÁ AL 95%, PERO EL ÍNDICE MÁS CERCANO
        %AL FINAL DE LA PLANTA SIN CONTROLAR
        indices_t = find(((w_planta >= (0.948*w_est_modelo)) & (w_planta <= (0.952*w_est_modelo))) | ((w_planta >= (1.048*w_est_modelo)) & (w_planta <= (1.052*w_est_modelo))));
        indice_t = max(indices_t);
        
        %OBTENER EL TIEMPO DE ASENTAMIENTO DE LA PLANTA SIN CONTROLAR
        ta_planta = t_pp(indice_t);
%       
%         ta_actual
%         ta_planta
%         ts
        
        %SI ESTÁ DENTRO DEL RANGO PERMITIDO, EL TIEMPO DE ASENTAMIENTO ES ACEPTADO
        if(ta_actual >= liminf_ts && ta_actual <= limsup_ts)
            ta_alcanzado = 1;
            disp("Este el Ts correcto")
        
        else
            %SI NO ESTÁ DENTRO DEL RANGO Y EL ts YA SUPERÓ EL 90% DEL
            %DE LA PLANTA MODELO, ENTONCES QUEDARNOS CON ESE ÚLTIMO
            %VALOR
            if(ta_actual == ta_previo || ts <= 0.002 || ta_actual < liminf_ts)
                ta_alcanzado = 1;
                disp("Este es el mejor tiempo de asentamiento alcanzable")
                
            %SI NO ESTÁ DENTRO DEL RANGO Y EL ts AUN NO SUPERA EL 90% DEL
            %DE LA PLANTA MODELO, ENTONCES AUMENTAR UN 10% DEL TS DE
            %DISEÑO
            else
                ts = ts*0.7;
                disp("Disminuyendo ts")
            end
        end
    end
    
    Ganancias(i,1) = K(1);
    Ganancias(i,2) = K(2);
    
    t_est(i,1) = ta_actual;
    max_s(i,1) = (max(w_pp)-w_est)/w_est;
    
    eee(i,1) = (w_est_modelo - w_est)*100/w_est_modelo;
        
end

J = transpose(J);

% dataset_predictoras = [J t_est max_s eee];
% dataset_objetivos = [Ganancias];

nombre_columnas = {'Inercia_Total','Ganancia_Corriente','Ganancia_Velocidad'};
dataset = table(J,Ganancias(:,1),Ganancias(:,2),'VariableNames',nombre_columnas);

nombre_columnas_carac = {'Tiempo_Establecimiento','Maximo_Sobrepico','Error_Estado_Estacionario'};
dataset_carac = table(t_est(:,1),max_s(:,1),eee(:,1),'VariableNames',nombre_columnas_carac);

writetable(dataset, 'Dataset_Motor.xlsx');
writetable(dataset_carac, 'Dataset_Motor_Respuesta.xlsx');