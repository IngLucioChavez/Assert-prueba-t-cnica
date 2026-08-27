1.	Describe un bug que hayas encontrado en producción: ¿cuál era el síntoma, ¿cuál fue la causa raíz y cómo lo resolviste?

el bug que indentifique en producción, fue consultas lentas en las bandejas de usuarios donde se registraban todos los procesos pendientes
respecto a una SI, estas bandejas se filtraban por id_usuario, unidad_gestion, carpeta_judicial_folio, estatus y fecha, pero estas bandejas
eran la unión de varias tablas como solicitudes, promociones, acuerdos, etc, tablas independientes en base de datos, lo que hice fue respectar la estructura de 
base de datos existente y tratar de indexar los campos que recibian más transacciones de filtrado, para hacer esto tuve que analizar las diferentes combinaciones de 
selects que llegaban con sus respectivos where y después analizar los campos más filtrados y aplicar indices, cabe mencionar que esto se realizo en caliente
ya que era un problema que estaba causando mucha lentitud en el sistema, con esa solución la base de datos procesaba más facilmente los select 
pero llego un punto donde no fue suficiente y para la etapa 2 tuve que realizar una vista en bds con una consulta general para que la bds hiciera 
sus respectivas estadisticas y en relación a la vista generada modifique el controlador que contenía la consulta principal de las bandejas

2.	¿Cómo integrarías un nuevo método de pago a un sistema de cobranza existente sin romper los flujos actuales?

a través de un patrón GoF por el strategy, ya que esté se centra en la aplicación de diferentes algoritmos sin tener que modificar la estructura base de una clase
respetando las reglas SOLID , Open y Close, abierto para extensión y cerrado para modificación, D inversión de dependencias, depender de interfaces o clases abstractas 

3.	¿Qué consideraciones de seguridad tendrías al diseñar una API que procesa transacciones financieras?

autentificación JWT y monosesión para que cada usuario pueda tener una y sola una sesión activa y el JWT para poder saber que usuario esta ingresando 
y compararlo con los datos almacenado en la base de datos o bien en un repositorio LDAP, además de tiempo de expiración en los tokens de sesión y por supuesto 
tener un servicio que permita la validación de permisos para saber que acciones tiene permitidas hacer el usuario, además de registro de logs para saber las acciones 
que genera cada usuario con tiempos e ips para rastreo

4.	¿Qué experiencia tienes con sistemas ERP? Describe el módulo más complejo que hayas desarrollado o mantenido.

he desarrollado módulos para la generación de expedientes digitales o carpetas judiciales que almacenan archivos digitales que se pueden subir manualmente a través de archivos PDF o words
utilizando el api de google para transformar un word a PDF, además de que al recibir una solicitud inicial o la generación de un cuaerdo o una promoción sus archivos se adjunten al expediente digital.
Todos estos archivos eran almacenados en un servidor llamado FILES que almacenaba los archivos y sus datos de ubicación se almacenaban en la bds para poder consultar el archivo, además que el servidor FILES,
tenía un proyecto laravel que regresaba una url temporal para consulta del archivo con enlaces simbólicos

5.	Un cliente reporta que una transacción se procesó dos veces. ¿Cuál es tu proceso de diagnóstico paso a paso?

    - ubico al usuario que generó el reporte en bds 
    - reviso todas las transacciones que ha realizado de los útimos 5 días
    - reviso los logs de transacciones para saber los momentos en que realizó dichas transacciones 
    - valido si en verdad existe duplicidad de proceso 
    - si es cierto busco la causa del problema que puede ser por latencia o por error de interfaz o por fallo de la bds y trato de simular el error en el ambiente de desarrollado
        después en el ambiente de calidad y realizo los ajustes necesarios para que el problema no vuelva a suceder y se trata de enmendar el error con el usuario en cuestión
    - si es falso pues sustento mi conclusión con registros en bds y logs y trasas de las transacciones realizadas por el usuario

6.	Describe una decisión técnica que hoy considerarías un error: ¿por qué te pareció correcta en su momento y qué te hizo cambiar de opinión?

utilizar querys como cadenas de texto en la programación de controladores o services, es decir raws, ya que a mis inicios como programador no sabía bien lo que implicaba esto
pero ahora se que eso puede generar vulnerabilidades en un sistema y puede ocasionar inyección de SQL revelando información delicada por eso cambie la implementación de consultas a la bds
a través de Query builder o modelos los cuales son una representación de las tablas en bds a través de clases 

7.	¿Qué herramienta, librería o práctica dejaste de usar en los últimos dos años y qué fue exactamente lo que te hizo abandonarla?

bootstrap y JQuery ya que tailwind hace lo mismo que bootstrap pero con relacion a nombre de clases más sencillas y comprensibles, además de que se pueden generar bien lo media query igual 
a través de nombres de clases y JQuery porque tarda mucho en cargar un página para cargar todas sus dependencias lo cual me hizo querer aprender REACT ya que es más fluido y permite la generación 
de componentes que pueden ser reutilizados en diferentes partes de un sitio web 

