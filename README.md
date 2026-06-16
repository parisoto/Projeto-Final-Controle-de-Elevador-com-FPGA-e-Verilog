# Controlador de Elevador - Placa Pitanga 🛗

Este repositório contém o código em Verilog para um controlador de elevador de 3 andares, desenvolvido especificamente para a placa FPGA educacional **Pitanga**.

## 📋 Sobre o Projeto

O projeto implementa uma Máquina de Estados Finita (FSM) que gerencia as operações de um elevador real ou maquete, incluindo:
* **Homing Automático:** Ao ser ligada, a placa inicia no estado de `HOMING`, garantindo que todas as portas sejam fechadas antes de aceitar chamadas.
* **Controle de Movimento:** Motores de subida e descida (`MOVE_UP` e `MOVE_DOWN`).
* **Controle de Portas:** Abertura, tempo de espera e fechamento (`DOOR_OPENING`, `DOOR_OPEN`, `DOOR_CLOSING`).
* **Feedback Visual:** Utiliza os displays de 7 segmentos da placa para mostrar o andar atual e indicadores visuais de "P A" (Porta Aberta).

## 🛠️ Máquina de Estados (FSM)
1. `HOMING` (0): Estado inicial de segurança.
2. `IDLE` (1): Aguardando chamadas.
3. `MOVE_UP` (2): Elevador subindo.
4. `MOVE_DOWN` (3): Elevador descendo.
5. `DOOR_OPENING` (4): Abrindo a porta do andar.
6. `DOOR_OPEN` (5): Porta aberta (com timer configurável).
7. `DOOR_CLOSING` (6): Fechando a porta.

## 🔌 Mapeamento de Pinos (Atuadores e Sensores)

| Componente | Função | Pino Pitanga |
| :--- | :--- | :--- |
| **LED 0** | Comando Abre Porta 1 | `cmd_abre_1` |
| **LED 1** | Comando Abre Porta 2 | `cmd_abre_2` |
| **LED 2** | Comando Abre Porta 3 | `cmd_abre_3` |
| **LED 3** | Comando Fecha Porta 1 | `cmd_fecha_1` |
| **LED 4** | Comando Fecha Porta 2 | `cmd_fecha_2` |
| **LED 5** | Comando Fecha Porta 3 | `cmd_fecha_3` |
| **LED 6** | Motor Subindo | `motor_sobe` |
| **LED 7** | Motor Descendo | `motor_desce` |
| **BTN 0-2** | Botões de Chamada (Andar 1 a 3) | `btn_1` a `btn_3` |
| **SW 0-2** | Fim de Curso (Andar 1 a 3) | `fc_1` a `fc_3` |
| **SW 3-5** | Sensores de Porta Aberta | `sens_aberta_1` a `3` |
| **SW 6-8** | Sensores de Porta Fechada | `sens_fechada_1` a `3` |

## 🚀 Como utilizar
1. Carregue o arquivo `projeto_elevador_pitanga.v` no ambiente da placa Pitanga.
2. Configure o mapeamento de pinos de acordo com o arquivo `pinagem.txt`.
3. Sintetize e grave na placa.
