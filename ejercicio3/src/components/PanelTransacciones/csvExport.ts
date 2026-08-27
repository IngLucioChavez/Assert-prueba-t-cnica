import type { Transaccion } from '../../types/transaccion';

const ENCABEZADOS = ['ID', 'Cliente', 'Monto', 'Estado', 'Fecha'] as const;

function escaparCampoCSV(valor: string | number): string {
  const texto = String(valor);
  if (/[",\n]/.test(texto)) {
    return `"${texto.replace(/"/g, '""')}"`;
  }
  return texto;
}

export function exportarCSV(transacciones: Transaccion[], nombreArchivo = 'transacciones_assert.csv'): void {
  if (transacciones.length === 0) return;

  const filas = transacciones.map((t) =>
    [t.id, t.cliente, t.monto, t.estado, t.fecha].map(escaparCampoCSV).join(','),
  );
  const contenido = [ENCABEZADOS.join(','), ...filas].join('\n');

  const blob = new Blob(['\ufeff' + contenido], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);

  const enlace = document.createElement('a');
  enlace.href = url;
  enlace.download = nombreArchivo;
  document.body.appendChild(enlace);
  enlace.click();
  document.body.removeChild(enlace);
  URL.revokeObjectURL(url);
}
