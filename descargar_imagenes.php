<?php

// --- Configuración ---
$base_url = "https://sirehv2-api.mem.gob.do/images/";
$carpeta_destino = "imagen";
$inicio = 1;
$fin = 1000;
// ---------------------

// 1. Crear la carpeta de destino si no existe
if (!is_dir($carpeta_destino)) {
    if (!mkdir($carpeta_destino, 0777, true)) {
        die("Error: No se pudo crear el directorio '$carpeta_destino'.");
    }
    echo "Directorio '$carpeta_destino' creado.\n";
}

// 2. Iterar sobre los números de 1 a 1000
for ($i = $inicio; $i <= $fin; $i++) {
    $nombre_archivo = $i . ".jpg";
    $url_completa = $base_url . $nombre_archivo;
    $ruta_destino = $carpeta_destino . "/" . $nombre_archivo;

    echo "Intentando descargar: " . $url_completa . "...\n";

    // Inicializar cURL
    $ch = curl_init();

    // Configurar cURL
    curl_setopt($ch, CURLOPT_URL, $url_completa);
    // Devuelve el resultado como una cadena en lugar de mostrarlo directamente
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    // No incluir los encabezados en el cuerpo de la respuesta
    curl_setopt($ch, CURLOPT_HEADER, false);
    // Establecer un timeout de conexión (opcional, pero recomendado)
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    // Seguir redireccionamientos (si los hubiera)
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

    // Ejecutar cURL y obtener el contenido
    $contenido = curl_exec($ch);

    // Obtener el código de estado HTTP
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    // Cerrar la sesión cURL
    curl_close($ch);

    // 3. Verificar el código de estado
    if ($http_code === 200) {
        // Código 200 significa OK, el archivo se encontró
        // Guardar el contenido en el archivo local
        if (file_put_contents($ruta_destino, $contenido) !== false) {
            echo "✅ ¡Éxito! Guardado como: " . $ruta_destino . "\n";
        } else {
            echo "❌ Error al guardar el archivo: " . $ruta_destino . "\n";
        }
    } elseif ($http_code === 404) {
        // Código 404 significa No Encontrado, se omite
        echo "⚠️ Omitido: Código de estado 404 (No Encontrado).\n";
    } else {
        // Otros errores (ej. 403, 500, etc.)
        echo "❌ Error al descargar: Código de estado HTTP: " . $http_code . "\n";
    }
    
    // Opcional: Pausa breve para no sobrecargar el servidor remoto (ajustar si es necesario)
    // usleep(50000); // Pausa de 50 milisegundos
}

echo "\nProceso de escaneo y descarga completado.\n";

?>
