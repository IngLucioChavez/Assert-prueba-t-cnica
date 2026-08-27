# ejercicio 1
- DUDA - que tipos de cuentas bancarias es posible manejar?
- ALTERNATIVA DESCARTADA - pense en hacer el tipo de cuenta con un type o enum pero después pense que estos tipos pueden ir creciendo con el tiempo 
- SUPUESTO - los tipos de cuentas bancarias las forme como un catálogo en bds
- SUPUESTO - decidi que si es posible eliminaciones que fueran eliminaciones lógicas para si después se quieren recuperar registros hacer rollback

# ejercicio 2
- DUDA - es posible trabajar con Query builder o con modelos?
- SUPUESTO - decidí usar query builder para hacer consultas a la base de datos para la resolución del bug 2
- SUPUESTO - decidi implementar la creación de transacción en bug 3 y 4, envuelta en una transaction para hacer rollback si en algún punto falla, además de envolver todo en un try catch para reporte de errores correctamente con código http

# ejercicio 4
- DUDA - para la expiración de tokens se podría actualizar el tiempo conforme el usuario tenga interacción con el sistema?