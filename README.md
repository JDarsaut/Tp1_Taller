# TP — Reserva concurrente de asientos (Condor del Sur)

## Descripcion

El proyecto implementa un sistema de reservas de asientos para un vuelo, con foco en **concurrencia, consistencia y comunicacion por mensajes**.

El sistema modela como multiples pasajeros pueden intentar reservar asientos simultaneamente, asegurando que **nunca haya doble asignacion** y que el estado se mantenga consistente.

---

## Conceptos implementados

* Procesos con estado (loop recursivo + `receive`)
* Comunicación por mensajes (`send`)
* Concurrencia entre multiples procesos
* Exclusion de recursos compartidos
* Procesos auxiliares (expiracion de reservas)
* Uso de `register` para acceso global
* Validacion de estados y transiciones

---

## Arquitectura

### 🔹 FlightServer (proceso principal)

Es el **unico dueño del estado del sistema**.

Se encarga de:

* Mantener el estado del vuelo
* Gestionar asientos y reservas
* Resolver conflictos concurrentes
* Validar reglas de negocio


### 🔹 ReservationExpirer (proceso auxiliar)

Proceso temporal que:

* espera 30 segundos
* envia un mensaje para expirar la reserva

Permite modelar tareas asincronicas sin bloquear el sistema.


### 🔹 Procesos cliente

Simulan pasajeros que:

* envian solicitudes concurrentes
* compiten por los mismos asientos

---

## Estados y transiciones

### Reserva

| Estado       | Descripcion              |
| ------------ | ------------------------ |
| `:pending`   | Reserva iniciada         |
| `:confirmed` | Confirmada               |
| `:cancelled` | Cancelada por usuario    |
| `:expired`   | Expirada automaticamente |

---

### Reglas importantes

* Un asiento no puede ser reservado por mas de un pasajero al mismo tiempo
* Una reserva confirmada no puede cancelarse
* Una reserva expirada libera el asiento
* La expiracion solo aplica a reservas `:pending`

---

## Como ejecutar el proyecto

### 1. Clonar el repositorio

```bash
git clone https://github.com/JDarsaut/Tp1_Taller.git
cd tp1_taller
```

---

### 2. Ejecutar en consola

```bash
iex -S mix
```

---

### 3. Ejecutar la demo

```elixir
Tp1Taller.CLI.Demo.run()
```

---

## Demo

La demo muestra:

* competencia concurrente por un asiento
* resolucion correcta del conflicto
* confirmacion de reserva
* cancelacion de reserva
* expiracion automatica
* comportamiento consistente del sistema

---

## Tests

* reservas de asientos
* manejo de concurrencia
* confirmación de reservas (con procesamiento asincrónico)
* cancelación de reservas
* expiración automática

---

## Conclusion

El sistema demuestra como modelar un problema de concurrencia en Elixir, manteniendo:

* consistencia
* aislamiento de estado
* coordinacion entre procesos

---

## Autor

Juan Ignacio Darsaut

