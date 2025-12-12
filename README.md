# API de Reportes

## Descripción del Proyecto

Esta es una API básica desarrollada en Dart para una aplicación de reportes. Sirve como backend para gestionar usuarios y reportes. Permite el registro y login de usuarios, la creación de reportes y la visualización de un feed principal de reportes.

La API utiliza Shelf para manejar las solicitudes HTTP y almacena los datos en memoria (se reinician al reiniciar el servidor). Es ideal para desarrollo y pruebas, pero para producción se recomienda integrar una base de datos persistente.

## Funcionalidades

- **Registro de Usuarios**: Permite crear cuentas con nombre de usuario, correo electrónico y contraseña.
- **Login de Usuarios**: Autentica usuarios con nombre de usuario y contraseña.
- **Creación de Reportes**: Los usuarios pueden crear reportes con título, descripción y autor.
- **Feed de Reportes**: Muestra una lista de todos los reportes creados.

## Endpoints

### GET /
- **Descripción**: Ruta básica que devuelve un mensaje de bienvenida.
- **Respuesta**: "Hello from API Reportes!"

### POST /register
- **Descripción**: Registra un nuevo usuario.
- **Cuerpo (JSON)**:
  ```json
  {
    "username": "ejemplo",
    "email": "ejemplo@correo.com",
    "password": "contraseña"
  }
  ```
- **Respuestas**:
  - 200: Usuario registrado exitosamente.
  - 400: Campos faltantes.
  - 409: Usuario ya existe.

### POST /login
- **Descripción**: Inicia sesión de un usuario.
- **Cuerpo (JSON)**:
  ```json
  {
    "username": "ejemplo",
    "password": "contraseña"
  }
  ```
- **Respuestas**:
  - 200: Login exitoso.
  - 401: Credenciales inválidas.

### POST /reports
- **Descripción**: Crea un nuevo reporte.
- **Cuerpo (JSON)**:
  ```json
  {
    "title": "Título del reporte",
    "description": "Descripción del reporte",
    "author": "Nombre del autor"
  }
  ```
- **Respuestas**:
  - 200: Reporte creado.
  - 400: Campos faltantes.

### GET /feed
- **Descripción**: Obtiene la lista de todos los reportes.
- **Respuesta**: JSON array de reportes.

## Instrucciones de Instalación y Ejecución

1. **Requisitos**:
   - Dart SDK instalado (versión >= 3.0.0).

2. **Instalación de Dependencias**:
   ```bash
   dart pub get
   ```

3. **Ejecución del Servidor**:
   ```bash
   dart run bin/main.dart
   ```
   El servidor se ejecutará en `http://localhost:8080`.

4. **Pruebas**:
   Usa herramientas como Postman, curl o un navegador para probar los endpoints.

## Ejemplos de Uso

### Registrar un Usuario
```bash
curl -X POST http://localhost:8080/register \
  -H "Content-Type: application/json" \
  -d '{"username":"usuario1","email":"usuario1@example.com","password":"pass123"}'
```

### Crear un Reporte
```bash
curl -X POST http://localhost:8080/reports \
  -H "Content-Type: application/json" \
  -d '{"title":"Reporte de Prueba","description":"Este es un reporte de ejemplo","author":"usuario1"}'
```

### Obtener el Feed
```bash
curl http://localhost:8080/feed
```

## Notas

- Las contraseñas se almacenan hasheadas con SHA-256 para seguridad básica.
- Los datos se pierden al reiniciar el servidor. Para persistencia, integra una base de datos como PostgreSQL o MongoDB.
- Esta API es básica y no incluye autenticación JWT o middleware avanzado. Se puede expandir según necesidades.