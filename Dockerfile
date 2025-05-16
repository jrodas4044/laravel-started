FROM php:8.2-fpm

# Arguments defined in docker-compose.yml
ARG user=laravel
ARG uid=1000

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    gnupg \
    apt-transport-https

# Instalar dependencias para SQL Server
RUN apt-get update \
    && curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-prod.gpg \
    && curl https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev

# Instalar extensiones PHP
RUN docker-php-ext-install pdo mbstring exif pcntl bcmath gd zip

# Instalar extensión pdo_sqlsrv para SQL Server
RUN pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv

# Limpiar cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Obtener Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crear usuario del sistema para ejecutar comandos Composer y Artisan
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Establecer directorio de trabajo
WORKDIR /var/www/html

# Copiar permisos de archivos de la aplicación
COPY --chown=$user:www-data . /var/www/html

# Cambiar al usuario no privilegiado
USER $user

# Exponer puerto 9000 y ejecutar php-fpm
EXPOSE 9000
CMD ["php-fpm"] 