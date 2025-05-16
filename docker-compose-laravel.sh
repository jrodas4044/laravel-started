#!/bin/bash

# Script para iniciar y ejecutar comandos en contenedores Docker para Laravel

# Colores para salidas del terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin Color

# Función para imprimir en colores
print_color() {
  printf "${!1}${2}${NC}\n"
}

# Función para imprimir ayuda
show_help() {
  echo "Uso: ./docker-compose-laravel.sh [COMANDO]"
  echo ""
  echo "Comandos disponibles:"
  echo "  start          - Inicia los contenedores de Docker"
  echo "  stop           - Detiene los contenedores de Docker"
  echo "  restart        - Reinicia los contenedores de Docker"
  echo "  ps             - Lista los contenedores en ejecución"
  echo "  artisan        - Ejecuta un comando de Artisan (ej. './docker-compose-laravel.sh artisan migrate')"
  echo "  composer       - Ejecuta un comando de Composer (ej. './docker-compose-laravel.sh composer require package')"
  echo "  npm            - Ejecuta un comando de NPM (ej. './docker-compose-laravel.sh npm install')"
  echo "  bash           - Inicia sesión bash en el contenedor app"
  echo "  sqlserver      - Inicia sesión SQL Server CLI en el contenedor db"
  echo "  createdb       - Crea la base de datos 'laravel' en SQL Server"
  echo "  setup          - Configura el proyecto para su primer uso (copiar .env, instalar dependencias, etc.)"
  echo "  help           - Muestra esta ayuda"
}

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
  print_color "RED" "Error: Docker no está instalado. Por favor instálelo primero."
  exit 1
fi

# Verificar si Docker Compose está instalado
if ! command -v docker compose &> /dev/null; then
  print_color "RED" "Error: Docker Compose no está instalado. Por favor instálelo primero."
  exit 1
fi

# Si no se pasan argumentos, mostrar ayuda
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

# Procesar comandos
case "$1" in
  start)
    print_color "BLUE" "Iniciando contenedores Docker..."
    docker compose up -d
    print_color "GREEN" "¡Contenedores iniciados con éxito! La aplicación está disponible en http://localhost:8000"
    ;;
    
  stop)
    print_color "BLUE" "Deteniendo contenedores Docker..."
    docker compose down
    print_color "GREEN" "¡Contenedores detenidos con éxito!"
    ;;
    
  restart)
    print_color "BLUE" "Reiniciando contenedores Docker..."
    docker compose down
    docker compose up -d
    print_color "GREEN" "¡Contenedores reiniciados con éxito!"
    ;;
    
  ps)
    print_color "BLUE" "Listando contenedores en ejecución..."
    docker compose ps
    ;;
    
  artisan)
    shift
    if [ $# -eq 0 ]; then
      print_color "YELLOW" "Por favor, especifique un comando de Artisan. Ejemplo: './docker-compose-laravel.sh artisan migrate'"
      exit 1
    fi
    print_color "BLUE" "Ejecutando comando Artisan: $@"
    docker compose exec app php artisan "$@"
    ;;
    
  composer)
    shift
    if [ $# -eq 0 ]; then
      print_color "YELLOW" "Por favor, especifique un comando de Composer. Ejemplo: './docker-compose-laravel.sh composer require package'"
      exit 1
    fi
    print_color "BLUE" "Ejecutando comando Composer: $@"
    docker compose exec app composer "$@"
    ;;
    
  npm)
    shift
    if [ $# -eq 0 ]; then
      print_color "YELLOW" "Por favor, especifique un comando de NPM. Ejemplo: './docker-compose-laravel.sh npm install'"
      exit 1
    fi
    print_color "BLUE" "Ejecutando comando NPM: $@"
    docker compose exec app npm "$@"
    ;;
    
  bash)
    print_color "BLUE" "Iniciando sesión bash en el contenedor app..."
    docker compose exec app bash
    ;;
    
  sqlserver)
    print_color "BLUE" "Iniciando sesión SQL Server CLI en el contenedor db..."
    docker compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P S3cureP@ssw0rd
    ;;
    
  createdb)
    print_color "BLUE" "Creando base de datos 'laravel' en SQL Server..."
    # Esperar a que SQL Server esté listo
    sleep 10
    docker compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P S3cureP@ssw0rd -Q "CREATE DATABASE laravel"
    print_color "GREEN" "¡Base de datos 'laravel' creada con éxito!"
    ;;
    
  setup)
    print_color "BLUE" "Configurando el proyecto para su primer uso..."
    
    # Copiar .env si no existe
    if [ ! -f .env ]; then
      if [ -f .env.example ]; then
        cp .env.example .env
        print_color "GREEN" "Archivo .env creado desde .env.example"
        
        # Actualizar configuración para SQL Server
        sed -i 's/DB_CONNECTION=mysql/DB_CONNECTION=sqlsrv/' .env
        sed -i 's/DB_HOST=127.0.0.1/DB_HOST=db/' .env
        sed -i 's/DB_PORT=3306/DB_PORT=1433/' .env
        sed -i 's/DB_USERNAME=root/DB_USERNAME=sa/' .env
        sed -i 's/DB_PASSWORD=/DB_PASSWORD=S3cureP@ssw0rd/' .env
        
        print_color "GREEN" "Configuración de .env actualizada para SQL Server"
      else
        print_color "RED" "No se encontró .env.example. Debes crear manualmente un archivo .env"
      fi
    else
      print_color "YELLOW" "Archivo .env ya existe. No se ha modificado."
    fi
    
    # Iniciar contenedores si no están en ejecución
    if ! docker compose ps | grep -q "Up"; then
      print_color "BLUE" "Iniciando contenedores Docker..."
      docker compose up -d
    fi
    
    # Esperar a que SQL Server esté listo
    print_color "BLUE" "Esperando a que SQL Server esté listo (30 segundos)..."
    sleep 30
    
    # Crear base de datos si no existe
    print_color "BLUE" "Creando base de datos 'laravel' en SQL Server..."
    docker compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P S3cureP@ssw0rd -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'laravel') BEGIN CREATE DATABASE laravel END"
    
    # Instalar dependencias de Composer
    print_color "BLUE" "Instalando dependencias de Composer..."
    docker compose exec app composer install
    
    # Instalar doctrine/dbal para soporte de SQL Server
    print_color "BLUE" "Instalando soporte para SQL Server..."
    docker compose exec app composer require doctrine/dbal
    
    # Instalar dependencias de NPM
    print_color "BLUE" "Instalando dependencias de NPM..."
    docker compose exec app npm install
    
    # Generar clave de la aplicación
    print_color "BLUE" "Generando clave de la aplicación..."
    docker compose exec app php artisan key:generate
    
    # Ejecutar migraciones
    print_color "BLUE" "Ejecutando migraciones de la base de datos..."
    docker compose exec app php artisan migrate
    
    print_color "GREEN" "¡Configuración completada con éxito! La aplicación está disponible en http://localhost:8000"
    ;;
    
  help)
    show_help
    ;;
    
  *)
    print_color "RED" "Comando desconocido: $1"
    show_help
    exit 1
    ;;
esac

exit 0 