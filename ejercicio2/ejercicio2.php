<?php
// Archivo: ejercicio2/TransaccionController.php
// Este controlador fue escrito por un desarrollador junior.
// Contiene exactamente 5 vulnerabilidades / bugs. Identifica y corrige cada uno.
// Escribe un comentario encima de cada problema explicando que falla y por que.
 
namespace App\Http\Controllers;
 
use App\Models\Transaccion;
use App\Models\Cliente;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Exception;
 
class TransaccionController extends Controller
{
    // Bug 1
    // falta de llave de apertura del método index
    public function index(Request $request) {
        $clienteId = $request->input('cliente_id');
 
        // Bug 2
        // query concatenado - puede generar inyección de SQL
        // se recomienda usar querybuilder 
        // y un select * revela la estrcutura de la tabla por lo tanto se recomienda
        // seleccionar campos especificos o bien formatear la respues en un DTO
        /*$rows = DB::select(
            "SELECT * FROM transacciones WHERE cliente_id = " . $clienteId 
        );*/
        $rows = DB::table("transacciones")
                    ->where("cliente_id","=",$clienteId)
                    ->get();
 
        return response()->json($rows);
    }
 
    public function store(Request $request)
    {
        // Bug 3
        // pasar $request->all() a una transaccion permite al usuario modificar campos
        // que no debería tener permiso de hacerlo, lo cual puede generar inconcistencias de información
        // y vulnerabilidad de seguridad, además de configurar validaciones para los campos recibidos 

        // validaciones de campos
        $request->validate([
            'id_cuenta' => 'required|integer|exists:cuentas,id_cuenta',
            'monto' => 'required|numeric|min:0.01',
            'tipo' => 'required|in:DEPOSITO,RETIRO,PAGO',
            'referencia' => 'nullable|string|max:100',
        ]);

        // Bug 4 
        // ejecutar una transacción sin envolver en un DB::transaction puede ocasionar
        // errores además de perdida de información o inconcistencia en los datos
        // se recomienda envolver la transacción con sus respectivas validaciones
        try {

            $t = DB::transaction(function () use ($request) {

                $cuenta = Cuenta::where('id_cuenta', $request->id_cuenta)
                    ->lockForUpdate() //bluqeo de dato hasta que se termine la transaccion
                    ->firstOrFail(); //obtiene el primer registro

                if (
                    $request->tipo !== 'DEPOSITO' &&
                    $cuenta->saldo < $request->monto
                ) {
                    throw new Exception('Saldo insuficiente');
                }

                $t = Transaccion::create([
                    'id_cuenta' => $cuenta->id_cuenta,
                    'monto' => $request->monto,
                    'tipo' => $request->tipo,
                    'referencia' => $request->referencia,
                ]);

                if ($request->tipo === 'DEPOSITO') {
                    $cuenta->increment('saldo', $request->monto);
                } else {
                    $cuenta->decrement('saldo', $request->monto);
                }

                return $t;
            });

            return response()->json($t, 201);

        } catch (Exception $e) {

            return response()->json([
                'message' => $e->getMessage()
            ], 400);
        }

    }
 
    public function resumenClientes()
    {
        $clientes = Cliente::all();

        // Bug 5
        // puede ocasionar consultas N+1, es decir, para 100 clientes puede traer todas las transacciones que han tenido
        // lo cual puede saturar la bds, se recomienda consulta eager loading o lazy
        $clientes = Cliente::with('transacciones')->get();

        return response()->json($clientes);

    }
}
