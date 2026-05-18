
## Struktura projektu

......

# Moduły (opis portów, założenia)

## Master FSM (`master_fsm.sv`)

Główna maszyna stanów (Finite State Machine) odpowiedzialna za zarządzanie trybami pracy silnika krokowego. Moduł dekoduje komendy wejściowe, nadzoruje proces dojazdu do zadanej pozycji oraz przeprowadza procedurę bazowania (kalibracji).

### Parametry

| Parametr | Typ | Domyślnie | Opis |
| :--- | :--- | :--- | :--- |
| `POS_RANGE` | `int` | `16` | Rozdzielczość (szerokość bitowa) rejestrów pozycji (`target_position` i `current_position`). |

### Porty

| Port | Kierunek | Szerokość | Opis |
| :--- | :---: | :---: | :--- |
| `clk` / `rst_n` | Input | 1 | Zegar systemowy oraz asynchroniczny reset aktywny stanem niskim. |
| `enable` | Input | 1 | Globalne zezwolenie na pracę układu. Stan `0` wymusza natychmiastowe zatrzymanie (Emergency Stop). |
| `callib` | Input | 1 | Żądanie rozpoczęcia procedury szukania pozycji zerowej. |
| `go_to` | Input | 1 | Komenda rozpoczęcia ruchu do pozycji `target_position`. |
| `sensor_clean` | Input | 1 | Przefiltrowany sygnał z czujnika krańcowego. |
| `target_position` | Input | `POS_RANGE` | Pozycja docelowa, do której ma przemieścić się silnik. |
| `current_position` | Input | `POS_RANGE` | Aktualna pozycja silnika pobierana z bloku *Step Counter*. |
| `set_zero` | Output| 1 | Wystawiany na `1` w stanie `CALLIB_DONE` w celu wyzerowania *Step Countera*. |
| `dir` | Output| 1 | Sygnał określający kierunek ruchu dla Sequencera i Countera. Zarejestrowany (stabilny). |
| `callib_done` | Output| 1 | Flaga zakończenia kalibracji. Obsługiwana w standardzie Handshake (czeka na wyzerowanie `callib`). |
| `prescaler_enable` | Output| 1 | Aktywuje *Prescaler*, zezwalając na generowanie fizycznych kroków silnika. |

### Kluczowe założenia behawioralne

1. **Emergency Stop (`enable = 0`):** Logika maszyny posiada asynchroniczny "overide". Spadek sygnału `enable` natychmiastowo zrzuca flagę `prescaler_enable` i nakazuje przejście maszyny do stanu `IDLE`, odcinając napęd z pominięciem standardowych przejść FSM.
2. **Kierunek w trybie kalibracji:** Podczas szukania czujnika krańcowego w stanie `CALLIB_FIND`, kierunek ruchu (`dir`) jest sztywno wymuszany na wartość `0`.
3. **Przerwanie normalnego ruchu:** Układ pozwala na bezwarunkowe przerwanie trwającego przemieszczania (`MOVE_RUN`) w momencie pojawienia się sygnału kalibracji (`callib = 1`).
4. **Protokół Handshake:** Stan po udanej kalibracji (`CALLIB_DONE`) jest stanem oczekującym. FSM nie przejdzie do stanu `IDLE`, dopóki układ nadrzędny (np. mikroprocesor) nie "zauważy" flagi `callib_done = 1` i nie obniży sygnału żądania `callib = 0`. Zapobiega to gubieniu flag i błędom synchronizacji przy krótkich impulsach.


## Sequencer (`sequencer.sv`)

Moduł dekodera i generatora faz dla silnika krokowego. Odpowiada za przeliczanie pojedynczych impulsów kroku (`step_tick`) na odpowiednią, wędrującą sekwencję sygnałów sterujących cewkami fizycznego silnika w oparciu o żądany kierunek.

### Parametry

| Parametr | Typ | Domyślnie | Opis |
| :--- | :--- | :--- | :--- |
| `COILS_NUM` | `int` | `4` | Ilość niezależnych cewek (faz) sterujących silnikiem. Narzuca szerokość magistrali wyjściowej i moduł zliczania. |

### Porty

| Port | Kierunek | Szerokość | Opis |
| :--- | :---: | :---: | :--- |
| `clk` / `rst_n` | Input | 1 | Zegar systemowy oraz asynchroniczny reset aktywny stanem niskim. |
| `step_tick` | Input | 1 | Sygnał wyzwalający wykonanie pojedynczego kroku (1 takt zegara). |
| `dir` | Input | 1 | Kierunek przesuwania sekwencji (`1` - w górę, `0` - w dół). |
| `inversion` | Input | 1 | Odwraca logicznie stany na cewkach wyjściowych (aktywny stan niski / wysoki). |
| `stepper_phases`| Output | `COILS_NUM` | Wyjściowa magistrala wędrującej sekwencji sterującej tranzystorami mocy (driverem). |

## Prescaler (`prescaler.sv`)

Sprzętowy dzielnik częstotliwości zegara głównego. Jego zadaniem jest odmierzanie czasu pomiędzy kolejnymi impulsami krokowymi napędzającymi silnik (regulacja prędkości obrotowej).

### Parametry

| Parametr | Typ | Domyślnie | Opis |
| :--- | :--- | :--- | :--- |
| `SCALE_WIDTH` | `int` | `32` | Szerokość magistrali rejestru wejściowego określającego stopień podziału częstotliwości. |

### Porty

| Port | Kierunek | Szerokość | Opis |
| :--- | :---: | :---: | :--- |
| `clk` / `rst_n` | Input | 1 | Zegar systemowy oraz asynchroniczny reset aktywny stanem niskim. |
| `enable` | Input | 1 | Zezwolenie z modułu nadrzędnego (FSM) na zliczanie i generowanie kroków. |
| `scale_val` | Input | `SCALE_WIDTH` | Docelowa wartość zliczana przez preskaler. Definiuje czas trwania jednego kroku. |
| `step_tick` | Output| 1 | Wyjściowy impuls o szerokości 1 taktu zegarowego wystawiany po odliczeniu zadanej wartości. |

## Step Counter (`step_counter.sv`)

Sprzętowy licznik cyfrowy rejestrujący aktualną pozycję silnika w przestrzeni.

### Parametry

| Parametr | Typ | Domyślnie | Opis |
| :--- | :--- | :--- | :--- |
| `POS_RANGE` | `int` | `32` | Szerokość rejestru przechowującego całkowitą, absolutną pozycję silnika. |

### Porty

| Port | Kierunek | Szerokość | Opis |
| :--- | :---: | :---: | :--- |
| `clk` / `rst_n` | Input | 1 | Zegar systemowy oraz asynchroniczny reset aktywny stanem niskim. |
| `step_tick` | Input | 1 | Impuls synchronizujący moment wykonania pojedynczego kroku. |
| `dir` | Input | 1 | Kierunek matematyczny (`1` -> inkrementacja, `0` -> dekrementacja). |
| `set_zero` | Input | 1 | Nadrzędny sygnał żądania wymuszenia na liczniku wartości "0". |
| `current_pos` | Output| `POS_RANGE` | Aktualna, absolutna pozycja układu mechanicznego. |

## Debouncer (`debouncer.sv`)

Cyfrowy filtr drgań styków przeznaczony do kondycjonowania fizycznych sygnałów zewnętrznych (np. mechanicznych wyłączników krańcowych). Zabezpiecza również układ przed stanami metastabilnymi przy wprowadzaniu asynchronicznych sygnałów z zewnątrz do domeny zegarowej FPGA.

### Parametry

| Parametr | Typ | Domyślnie | Opis |
| :--- | :--- | :--- | :--- |
| `DELAY_CYCLES`| `int` | `1000000` | Czas (w cyklach zegarowych) wymagany do potwierdzenia stabilności sygnału. Dla 100 MHz domyślna wartość to 10 ms. |

### Porty

| Port | Kierunek | Szerokość | Opis |
| :--- | :---: | :---: | :--- |
| `clk` / `rst_n` | Input | 1 | Zegar systemowy oraz asynchroniczny reset aktywny stanem niskim. |
| `signal_in` | Input | 1 | Asynchroniczny, "surowy" i zaszumiony sygnał wejściowy ze środowiska zewnętrznego. |
| `cleared_signal`| Output| 1 | Synchroniczny, odfiltrowany sygnał wprowadzany do głównej logiki maszyny FSM. |
