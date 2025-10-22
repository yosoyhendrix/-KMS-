<?php

// Lista de funciones de ejecución de comandos peligrosas a comprobar.
$funciones_a_comprobar = [
    'exec', 
    'system', 
    'shell_exec', 
    'passthru', 
    'popen', 
    'proc_open', 
    'pcntl_exec',
    'bypass_shell'
];

echo "<h2>Verificación de Funciones de Ejecución de Comandos (Seguridad)</h2>";
echo "<table border='1' cellpadding='10' cellspacing='0'>";
echo "<tr><th>Función</th><th>Estado</th><th>Recomendación de Seguridad</th></tr>";

// Iterar sobre la lista y comprobar el estado de cada función.
foreach ($funciones_a_comprobar as $funcion) {
    echo "<tr>";
    echo "<td><strong>" . $funcion . "</strong></td>";
    
    // Comprobar si la función existe y está disponible.
    if (function_exists($funcion)) {
        echo "<td style='background-color:#FDD;'><strong>❌ HABILITADA</strong></td>";
        echo "<td>⚠️ **Deshabilitar** en `php.ini` (directiva `disable_functions`) para prevenir la Inyección de Comandos.</td>";
    } else {
        echo "<td style='background-color:#DFD;'><strong>✅ DESHABILITADA</strong></td>";
        echo "<td>Buena práctica de seguridad.</td>";
    }
    
    echo "</tr>";
}

echo "</table>";

?>
