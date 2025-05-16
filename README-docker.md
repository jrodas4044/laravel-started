# Laravel con Docker

Este proyecto está configurado para ejecutarse con Docker, permitiendo un entorno de desarrollo consistente y aislado. La configuración incluye SQL Server como base de datos según los requerimientos del cliente.

## Requisitos previos

-   [Docker](https://www.docker.com/get-started)
-   [Docker Compose](https://docs.docker.com/compose/install/)

## Servicios incluidos

-   **app**: Servicio principal de PHP 8.2 con Laravel y Composer
-   **nginx**: Servidor web que redirige las peticiones al servicio app
-   **db**: Servidor SQL Server 2019 para la base de datos
-   **redis**: Servicio Redis para caché, sesiones y colas

## Instrucciones de uso

Hemos incluido un script (`docker-compose-laravel.sh`) para facilitar las operaciones comunes:

### Configuración inicial

Para configurar el proyecto por primera vez:

```bash
./docker-compose-laravel.sh setup
```

Este comando:

1. Copia `.env.example` a `.env` si no existe
2. Actualiza automáticamente el archivo .env para utilizar SQL Server
3. Inicia los contenedores
4. Espera a que SQL Server esté listo
5. Crea automáticamente la base de datos 'laravel' en SQL Server
6. Instala dependencias de Composer y NPM (incluyendo doctrine/dbal para soporte SQL Server)
7. Genera la clave de la aplicación
8. Ejecuta las migraciones de la base de datos

### Comandos disponibles

-   **Iniciar contenedores**:

    ```bash
    ./docker-compose-laravel.sh start
    ```

-   **Detener contenedores**:

    ```bash
    ./docker-compose-laravel.sh stop
    ```

-   **Reiniciar contenedores**:

    ```bash
    ./docker-compose-laravel.sh restart
    ```

-   **Ver contenedores en ejecución**:

    ```bash
    ./docker-compose-laravel.sh ps
    ```

-   **Crear base de datos**:

    ```bash
    ./docker-compose-laravel.sh createdb
    ```

-   **Ejecutar comandos Artisan**:

    ```bash
    ./docker-compose-laravel.sh artisan migrate
    ./docker-compose-laravel.sh artisan make:controller UserController
    ```

-   **Ejecutar comandos Composer**:

    ```bash
    ./docker-compose-laravel.sh composer require package-name
    ```

-   **Ejecutar comandos NPM**:

    ```bash
    ./docker-compose-laravel.sh npm install
    ./docker-compose-laravel.sh npm run dev
    ```

-   **Acceder al shell del contenedor**:

    ```bash
    ./docker-compose-laravel.sh bash
    ```

-   **Acceder a SQL Server CLI**:
    ```bash
    ./docker-compose-laravel.sh sqlserver
    ```

## Configuración manual

Si prefieres usar Docker Compose directamente:

1. **Iniciar contenedores**:

    ```bash
    docker compose up -d
    ```

2. **Crear la base de datos** (si no se usó el comando setup):

    ```bash
    docker compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P S3cureP@ssw0rd -Q "CREATE DATABASE laravel"
    ```

3. **Ejecutar comandos en el contenedor**:

    ```bash
    docker compose exec app php artisan migrate
    docker compose exec app composer install
    ```

4. **Detener contenedores**:
    ```bash
    docker compose down
    ```

## Acceso a la aplicación

Una vez iniciados los contenedores, puedes acceder a la aplicación en:

-   **URL**: [http://localhost:8000](http://localhost:8000)

## Configuración de la base de datos

La configuración predeterminada de SQL Server es:

-   **Host**: db (dentro de Docker) / localhost (acceso externo en puerto 1433)
-   **Base de datos**: laravel (creada automáticamente durante el setup)
-   **Usuario**: sa
-   **Contraseña**: S3cureP@ssw0rd

Estos valores pueden ser modificados en el archivo `docker-compose.yml`.

## Volúmenes persistentes

-   La base de datos persiste los datos en un volumen Docker llamado `sqlserver_data`

## Acceso directo a los contenedores

Para acceder directamente a los contenedores:

```bash
docker compose exec app bash
docker compose exec db bash
docker compose exec redis redis-cli
```

## Paquetes necesarios en Laravel para SQL Server

El comando `setup` ya instala automáticamente el paquete necesario para trabajar con SQL Server en Laravel:

```bash
./docker-compose-laravel.sh composer require doctrine/dbal
```

## Funcionamiento con SQL Server

Aunque Laravel soporta SQL Server, existen algunas consideraciones:

1. Las migraciones y esquemas funcionan bien, pero algunas funciones específicas de MySQL pueden requerir modificaciones.
2. Asegúrate de que tus consultas sean compatibles con SQL Server, especialmente si utilizas consultas raw o funciones específicas de MySQL.

## Troubleshooting

### Problemas comunes

1. **Puertos ocupados**: Si los puertos 8000, 1433 o 6379 están ocupados, modifícalos en el archivo `docker-compose.yml`.

2. **Problemas de permisos de archivos**: Los archivos creados dentro de los contenedores pueden tener problemas de permisos. Desde el host ejecuta:

    ```bash
    sudo chown -R $USER: .
    ```

3. **Cambios en .env**: Si modificas variables relacionadas con servicios en `.env`, reinicia los contenedores:

    ```bash
    ./docker-compose-laravel.sh restart
    ```

4. **Error de conexión a SQL Server**: Si tienes problemas conectándote a SQL Server, asegúrate de que el servicio esté funcionando correctamente:

    ```bash
    docker compose logs db
    ```

5. **Timeout en las migraciones**: Las migraciones pueden tardar más con SQL Server. Si ocurre un timeout, incrementa el valor de `default_migration_command_timeout` en el archivo `config/database.php`.

6. **SQL Server no inicia correctamente**: La imagen de SQL Server requiere al menos 2GB de RAM asignados a Docker. Verifica la configuración de recursos de Docker en tu máquina.
