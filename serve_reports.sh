#!/bin/bash
set -e

# Directorio raíz del proyecto (detecta dónde está el script)
PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RESULTS_DIR="$PROJECT_DIR/ansible/results"
NGINX_CONF_FILE="/etc/nginx/sites-available/jmeter-reports"
NGINX_ENABLED_FILE="/etc/nginx/sites-enabled/jmeter-reports"

echo "--- Configurando Nginx para servir reportes ---"

# 1. Instalar Nginx si no existe
if ! command -v nginx &> /dev/null
then
    echo "Nginx no encontrado, instalando..."
    apt update
    apt install nginx -y
fi

# 2. Crear el directorio de resultados si no existe
mkdir -p "$RESULTS_DIR/spring-boot-dashboard"
mkdir -p "$RESULTS_DIR/fastapi-dashboard"
echo "-> Directorio de resultados asegurado en $RESULTS_DIR"

# 3. Crear la configuración de Nginx
echo "Creando configuración de Nginx en $NGINX_CONF_FILE..."
cat << EOF > $NGINX_CONF_FILE
server {
    listen 80;
    server_name _;
    
    # Redirección de la raíz a la página de Spring Boot
    location = / {
        return 301 /spring/;
    }

    # Ubicación para el reporte de Spring Boot
    location /spring/ {
        alias "$RESULTS_DIR/spring-boot-dashboard/";
        index index.html;
        autoindex on;
    }

    # Ubicación para el reporte de FastAPI
    location /fastapi/ {
        alias "$RESULTS_DIR/fastapi-dashboard/";
        index index.html;
        autoindex on;
    }
}
EOF

# 4. Activar el sitio
if [ ! -L "$NGINX_ENABLED_FILE" ]; then
    echo "Activando el sitio jmeter-reports..."
    ln -s "$NGINX_CONF_FILE" "$NGINX_ENABLED_FILE"
fi

# 5. Desactivar el sitio por defecto si existe
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    echo "Desactivando sitio por defecto de Nginx..."
    rm /etc/nginx/sites-enabled/default
fi

# 6. Arreglar permisos de /root (¡IMPORTANTE!)
# Nginx (usuario www-data) no puede entrar a /root por defecto.
# Este comando da permiso de 'ejecutar' (entrar) a /root y a las carpetas intermedias.
echo "Ajustando permisos de /root para Nginx (www-data)..."
chmod 711 /root
chmod 711 "$PROJECT_DIR"
chmod 711 "$PROJECT_DIR/ansible"
chmod 711 "$PROJECT_DIR/ansible/results"
# Asegurar que www-data pueda leer los archivos del reporte
chown -R www-data:www-data "$RESULTS_DIR"
chmod -R 755 "$RESULTS_DIR"


# 7. Probar y reiniciar Nginx
nginx -t
if [ $? -ne 0 ]; then
  echo "¡Error en la configuración de Nginx! Abortando."
  exit 1
fi

systemctl restart nginx

# 8. Abrir Firewall (UFW) por si está activo
if command -v ufw &> /dev/null && ufw status | grep -q 'Status: active'; then
    echo "Abriendo puerto 80/tcp en el firewall UFW..."
    ufw allow 80/tcp
fi

echo "¡Éxito! Nginx está sirviendo los reportes."
echo ""
echo "Accede al reporte de Spring Boot en: http://<TU_IP_PUBLICA_LOCAL>/spring/"
echo "Accede al reporte de FastAPI en:   http://<TU_IP_PUBLICA_LOCAL>/fastapi/"
