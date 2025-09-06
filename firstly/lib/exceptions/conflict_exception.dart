/// Exceção lançada quando há conflitos de versão (concorrência)
class ConflictException implements Exception {
  final String message;
  final dynamic localData;
  final dynamic remoteData;
  final ConflictType type;

  ConflictException(
    this.message, {
    this.localData,
    this.remoteData,
    this.type = ConflictType.version,
  });

  @override
  String toString() => 'ConflictException: $message';
}

/// Tipos de conflito que podem ocorrer
enum ConflictType {
  version, // Conflito de versão optimistic
  deleted, // Item foi deletado enquanto estava sendo editado
  duplicate, // Tentativa de adicionar item duplicado
}

/// Opções de resolução de conflito
enum ConflictResolution {
  keepLocal, // Manter versão local
  keepRemote, // Manter versão remota
  merge, // Tentar fazer merge
  cancel, // Cancelar operação
}
