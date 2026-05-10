
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