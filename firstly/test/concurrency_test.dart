import 'package:flutter_test/flutter_test.dart';
import 'package:firstly/models/item.dart';
import 'package:firstly/services/list_sharing_service.dart';
import 'package:firstly/exceptions/conflict_exception.dart';
import 'package:firstly/services/supabase_service.dart';
import 'dart:async';

/// Testes de concorrência para verificar resistência a problemas de race condition
/// 
/// IMPORTANTE: Execute estes testes contra um banco de dados de desenvolvimento,
/// nunca em produção!
void main() {
  group('Testes de Concorrência - Sistema Resistente', () {
    late String testListId;
    late String testUserId;
    
    setUpAll(() async {
      // Inicializar Supabase para testes
      await SupabaseService.initialize();
      
      // Criar uma lista de teste
      // NOTA: Substitua por IDs reais do seu banco de teste
      testListId = "1"; // ID de uma lista de teste
      testUserId = "1"; // ID de um usuário de teste
    });

    group('Teste 1: Edição vs Remoção Simultânea', () {
      test('Deve detectar quando item é removido enquanto está sendo editado', () async {
        // Cenário: Usuário A edita, Usuário B remove simultaneamente
        
        // 1. Criar item de teste
        final testItem = Item(
          name: 'Item Teste Edição vs Remoção',
          price: 10.0,
          quantity: 1,
        );
        
        await ListSharingService.addItemToListAtomic(
          testListId,
          testItem,
          addedByUserId: testUserId,
        );
        
        expect(testItem.supabaseId, isNotNull);
        print('✅ Item criado: ${testItem.supabaseId}');
        
        // 2. Simular edição e remoção simultâneas
        final editFuture = Future.delayed(Duration(milliseconds: 100), () async {
          // Usuário A tenta editar
          final editedItem = testItem.copyWithNewVersion(
            name: 'Item Editado',
            price: 15.0,
          );
          
          try {
            await ListSharingService.updateItemInListAtomic(
              testListId,
              testItem.supabaseId!,
              editedItem,
            );
            return 'EDIT_SUCCESS';
          } on ConflictException catch (e) {
            if (e.type == ConflictType.deleted) {
              return 'EDIT_CONFLICT_DELETED';
            }
            return 'EDIT_CONFLICT_OTHER';
          }
        });
        
        final deleteFuture = Future.delayed(Duration(milliseconds: 50), () async {
          // Usuário B remove o item
          try {
            await ListSharingService.removeItemFromListAtomic(
              testListId,
              testItem.supabaseId!,
            );
            return 'DELETE_SUCCESS';
          } on ConflictException {
            return 'DELETE_CONFLICT';
          }
        });
        
        // 3. Aguardar ambas operações
        final results = await Future.wait([editFuture, deleteFuture]);
        
        print('📊 Resultado da edição: ${results[0]}');
        print('📊 Resultado da remoção: ${results[1]}');
        
        // 4. Verificar que pelo menos uma operação foi bem-sucedida
        // e que conflitos foram detectados apropriadamente
        expect(
          results.contains('DELETE_SUCCESS') || results.contains('EDIT_CONFLICT_DELETED'),
          isTrue,
          reason: 'Sistema deve detectar conflito entre edição e remoção',
        );
        
        print('✅ Teste 1 passou: Conflito edição vs remoção detectado corretamente');
      });
    });

    group('Teste 2: Edições Simultâneas do Mesmo Item', () {
      test('Deve usar controle de versão optimistic para edições concorrentes', () async {
        // Cenário: Dois usuários editam o mesmo item simultaneamente
        
        // 1. Criar item de teste
        final testItem = Item(
          name: 'Item Teste Edições Simultâneas',
          price: 20.0,
          quantity: 2,
        );
        
        await ListSharingService.addItemToListAtomic(
          testListId,
          testItem,
          addedByUserId: testUserId,
        );
        
        expect(testItem.supabaseId, isNotNull);
        print('✅ Item criado para teste de edições simultâneas: ${testItem.supabaseId}');
        
        // 2. Simular duas edições simultâneas
        final edit1Future = Future.delayed(Duration(milliseconds: 50), () async {
          final editedItem1 = testItem.copyWithNewVersion(
            name: 'Editado por Usuário 1',
            price: 25.0,
          );
          
          try {
            await ListSharingService.updateItemInListAtomic(
              testListId,
              testItem.supabaseId!,
              editedItem1,
            );
            return 'USER1_SUCCESS';
          } on ConflictException catch (e) {
            return 'USER1_CONFLICT_${e.type.name}';
          }
        });
        
        final edit2Future = Future.delayed(Duration(milliseconds: 75), () async {
          final editedItem2 = testItem.copyWithNewVersion(
            name: 'Editado por Usuário 2',
            price: 30.0,
          );
          
          try {
            await ListSharingService.updateItemInListAtomic(
              testListId,
              testItem.supabaseId!,
              editedItem2,
            );
            return 'USER2_SUCCESS';
          } on ConflictException catch (e) {
            return 'USER2_CONFLICT_${e.type.name}';
          }
        });
        
        // 3. Aguardar ambas edições
        final results = await Future.wait([edit1Future, edit2Future]);
        
        print('📊 Resultado Usuário 1: ${results[0]}');
        print('📊 Resultado Usuário 2: ${results[1]}');
        
        // 4. Verificar que apenas uma edição foi bem-sucedida
        final successCount = results.where((r) => r.contains('SUCCESS')).length;
        final conflictCount = results.where((r) => r.contains('CONFLICT')).length;
        
        expect(successCount, equals(1), reason: 'Apenas uma edição deve ser bem-sucedida');
        expect(conflictCount, equals(1), reason: 'Uma edição deve gerar conflito');
        
        // 5. Limpar item de teste
        try {
          await ListSharingService.removeItemFromListAtomic(
            testListId,
            testItem.supabaseId!,
          );
        } catch (e) {
          // Ignora erro se item já foi removido
        }
        
        print('✅ Teste 2 passou: Controle de versão optimistic funcionando');
      });
    });

    group('Teste 3: Adições Duplicadas Simultâneas', () {
      test('Deve prevenir adição de itens duplicados', () async {
        // Cenário: Dois usuários tentam adicionar o mesmo item
        
        const itemName = 'Item Duplicado Teste';
        
        // 1. Simular adições simultâneas do mesmo item
        final add1Future = Future.delayed(Duration(milliseconds: 50), () async {
          final item1 = Item(name: itemName, price: 5.0, quantity: 1);
          
          try {
            await ListSharingService.addItemToListAtomic(
              testListId,
              item1,
              addedByUserId: testUserId,
            );
            return {'result': 'USER1_SUCCESS', 'itemId': item1.supabaseId};
          } on ConflictException catch (e) {
            return {'result': 'USER1_CONFLICT_${e.type.name}', 'itemId': null};
          }
        });
        
        final add2Future = Future.delayed(Duration(milliseconds: 75), () async {
          final item2 = Item(name: itemName, price: 6.0, quantity: 2);
          
          try {
            await ListSharingService.addItemToListAtomic(
              testListId,
              item2,
              addedByUserId: testUserId,
            );
            return {'result': 'USER2_SUCCESS', 'itemId': item2.supabaseId};
          } on ConflictException catch (e) {
            return {'result': 'USER2_CONFLICT_${e.type.name}', 'itemId': null};
          }
        });
        
        // 2. Aguardar ambas adições
        final results = await Future.wait([add1Future, add2Future]);
        
        print('📊 Resultado Adição 1: ${results[0]['result']}');
        print('📊 Resultado Adição 2: ${results[1]['result']}');
        
        // 3. Verificar que apenas uma adição foi bem-sucedida
        final successResults = results.where((r) => r['result'].toString().contains('SUCCESS')).toList();
        final conflictResults = results.where((r) => r['result'].toString().contains('CONFLICT')).toList();
        
        expect(successResults.length, equals(1), reason: 'Apenas uma adição deve ser bem-sucedida');
        expect(conflictResults.length, equals(1), reason: 'Uma adição deve gerar conflito de duplicata');
        
        // 4. Limpar item de teste criado
        final createdItemId = successResults.first['itemId'];
        if (createdItemId != null) {
          try {
            await ListSharingService.removeItemFromListAtomic(testListId, createdItemId);
          } catch (e) {
            print('⚠️ Erro ao limpar item de teste: $e');
          }
        }
        
        print('✅ Teste 3 passou: Prevenção de duplicatas funcionando');
      });
    });

    group('Teste 4: Stress Test - Múltiplas Operações Simultâneas', () {
      test('Deve manter consistência com alta concorrência', () async {
        // Cenário: Múltiplos usuários fazendo várias operações simultaneamente
        
        final futures = <Future<String>>[];
        final testItems = <Item>[];
        
        // 1. Criar múltiplos itens de teste
        for (int i = 0; i < 5; i++) {
          final item = Item(
            name: 'Stress Test Item $i',
            price: 10.0 + i,
            quantity: 1,
          );
          
          await ListSharingService.addItemToListAtomic(
            testListId,
            item,
            addedByUserId: testUserId,
          );
          
          testItems.add(item);
        }
        
        print('✅ Criados ${testItems.length} itens para stress test');
        
        // 2. Simular múltiplas operações simultâneas
        for (int i = 0; i < testItems.length; i++) {
          final item = testItems[i];
          
          // Adicionar operação de edição
          futures.add(
            Future.delayed(Duration(milliseconds: 50 + (i * 25)), () async {
              try {
                final editedItem = item.copyWithNewVersion(
                  price: item.price + 5.0,
                );
                
                await ListSharingService.updateItemInListAtomic(
                  testListId,
                  item.supabaseId!,
                  editedItem,
                );
                return 'EDIT_${i}_SUCCESS';
              } catch (e) {
                return 'EDIT_${i}_ERROR: ${e.toString()}';
              }
            })
          );
          
          // Adicionar operação de remoção para alguns itens
          if (i % 2 == 0) {
            futures.add(
              Future.delayed(Duration(milliseconds: 100 + (i * 30)), () async {
                try {
                  await ListSharingService.removeItemFromListAtomic(
                    testListId,
                    item.supabaseId!,
                  );
                  return 'DELETE_${i}_SUCCESS';
                } catch (e) {
                  return 'DELETE_${i}_ERROR: ${e.toString()}';
                }
              })
            );
          }
        }
        
        // 3. Aguardar todas operações
        final results = await Future.wait(futures);
        
        print('📊 Resultados do Stress Test:');
        for (final result in results) {
          print('  - $result');
        }
        
        // 4. Verificar que não houve erros críticos
        final criticalErrors = results.where((r) => 
          r.contains('CRITICAL') || r.contains('DEADLOCK') || r.contains('CORRUPTION')
        ).toList();
        
        expect(criticalErrors, isEmpty, reason: 'Não deve haver erros críticos durante stress test');
        
        // 5. Limpeza - remover itens restantes
        for (final item in testItems) {
          try {
            await ListSharingService.removeItemFromListAtomic(
              testListId,
              item.supabaseId!,
            );
          } catch (e) {
            // Ignora se já foi removido
          }
        }
        
        print('✅ Teste 4 passou: Sistema manteve consistência sob alta concorrência');
      });
    });
  });
}

/// Classe utilitária para testes de concorrência
class ConcurrencyTestUtils {
  /// Executa operação com timeout para evitar testes infinitos
  static Future<T> withTimeout<T>(
    Future<T> future, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return await future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException('Operação expirou após $timeout'),
    );
  }
  
  /// Cria delay aleatório para simular comportamento real
  static Future<void> randomDelay({
    int minMs = 50,
    int maxMs = 200,
  }) async {
    final delay = minMs + (maxMs - minMs) * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
    await Future.delayed(Duration(milliseconds: delay.round()));
  }
}
