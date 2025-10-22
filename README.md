# CIS Benchmark para Ubuntu Server 24.04 TLS v1.0.0

Este proyecto proporciona un conjunto de scripts de shell para configurar un sistema Ubuntu Server de acuerdo con los Benchmarks de CIS (Center for Internet Security). Los scripts tienen como objetivo mejorar la postura de seguridad del servidor aplicando configuraciones recomendadas en varios componentes del sistema.

## Uso

### Ejecutando la Auditoría

Para ejecutar la auditoría CIS, navegue hasta el directorio del proyecto y ejecute el script principal con privilegios de root:

```bash
sudo ./cis-audit.sh
```

### Opciones de Línea de Comandos

El script principal acepta las siguientes opciones de línea de comandos:

- `-h`, `--help`: Muestra el mensaje de ayuda.
- `--fix-configs`: Aplica automáticamente las correcciones para las configuraciones erróneas identificadas. **Úselo con precaución, ya que esto modificará su sistema.**
- `--allowed-programs=<ruta>`: Especifica un archivo que contiene una lista de programas permitidos. Esta opción es utilizada por la función `allowed_programs.sh` (si está integrada) para determinar qué programas están permitidos en el sistema.

**Ejemplo con `--allowed-programs`:**

```bash
sudo ./cis-audit.sh --allowed-programs=<path_file>
```
o
```bash
sudo ./cis-audit.sh --allowed-programs path_file
```

## Registro de Errores

Todos los errores generados durante la ejecución de los scripts de configuración se redirigen a un archivo de registro ubicado en `logs/errors.log`. Este archivo se puede utilizar para solucionar cualquier problema encontrado durante el proceso de auditoría o configuración.