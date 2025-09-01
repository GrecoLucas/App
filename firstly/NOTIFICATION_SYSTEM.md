# Sistema de Notificações de Convites

Este documento explica as mudanças implementadas para o sistema de notificações de convites de listas.

## Funcionalidades Implementadas

### 1. Página de Notificações
- **Arquivo**: `lib/screens/notification_page.dart`
- **Funcionalidade**: Exibe todos os convites pendentes para o usuário atual
- **Características**:
  - Lista todos os convites com informações detalhadas
  - Mostra nome da lista, quem convidou, data/hora do convite
  - Permite aceitar ou rejeitar convites
  - Atualização em tempo real após ações
  - Pull-to-refresh para atualizar a lista
  - Estados de loading, erro e lista vazia

### 2. Modelo de Convite
- **Arquivo**: `lib/models/list_invitation.dart`
- **Funcionalidade**: Modelo de dados para representar convites
- **Campos**:
  - `id`: Identificador único do convite
  - `listId`: ID da lista sendo compartilhada
  - `listName`: Nome da lista
  - `inviterUsername`: Usuário que enviou o convite
  - `invitedUsername`: Usuário que recebeu o convite
  - `createdAt`: Data/hora do convite
  - `status`: Status ('pending', 'accepted', 'rejected')

### 3. Serviço de Notificações
- **Arquivo**: `lib/services/notification_service.dart`
- **Funcionalidades**:
  - `getUserInvitations()`: Busca convites pendentes do usuário
  - `acceptInvitation()`: Aceita um convite e adiciona à lista compartilhada
  - `rejectInvitation()`: Rejeita um convite
  - `createInvitation()`: Cria novo convite
  - `getPendingInvitationsCount()`: Conta convites pendentes

### 4. Modificações no Profile Screen
- **Arquivo**: `lib/screens/profile_screen.dart`
- **Mudanças**:
  - Adicionado badge com número de notificações pendentes
  - Integração com a página de notificações
  - Atualização automática da contagem ao voltar da página

### 5. Modificações no Compartilhamento
- **Arquivo**: `lib/services/list_sharing_service.dart`
- **Mudança**: Em vez de adicionar diretamente o usuário à lista, agora cria um convite que deve ser aceito

## Configuração do Banco de Dados

### Script SQL para Supabase
Execute o script em `database_setup.sql` no editor SQL do Supabase para criar:

1. **Tabela `list_invitations`**: Armazena os convites
2. **Índices**: Para melhor performance nas consultas
3. **Políticas RLS**: Segurança a nível de linha
4. **Triggers**: Atualização automática de timestamps

### Estrutura da Tabela
```sql
CREATE TABLE list_invitations (
    id BIGSERIAL PRIMARY KEY,
    list_id BIGINT REFERENCES shopping_lists(id) ON DELETE CASCADE,
    list_name TEXT NOT NULL,
    inviter_username TEXT NOT NULL,
    invited_username TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Fluxo de Funcionamento

### 1. Envio de Convite
1. Usuário vai na lista → Compartilhar
2. Digite nome do usuário
3. Sistema cria convite na tabela `list_invitations`
4. Convite fica com status 'pending'

### 2. Visualização de Convites
1. Usuário vai no Perfil → Notificações
2. Sistema busca convites pendentes
3. Exibe lista com detalhes de cada convite

### 3. Aceitar Convite
1. Usuário clica em "Aceitar"
2. Sistema atualiza status para 'accepted'
3. Usuário é adicionado à tabela `shared_lists`
4. Convite some da lista de pendentes

### 4. Rejeitar Convite
1. Usuário clica em "Rejeitar"
2. Sistema atualiza status para 'rejected'
3. Convite some da lista de pendentes

## Recursos Visuais

### Badge de Notificações
- Aparece no botão "Notificações" do perfil
- Mostra número de convites pendentes
- Cor vermelha para chamar atenção
- Atualiza automaticamente

### Cards de Convite
- Design limpo e informativo
- Ícone da lista
- Informações do convitante
- Data/hora formatada
- Botões de ação (Aceitar/Rejeitar)

### Estados da Página
- **Loading**: Indicador de carregamento
- **Erro**: Mensagem de erro com opção de retry
- **Vazio**: Mensagem quando não há convites
- **Lista**: Cards com convites pendentes

## Segurança

### Políticas RLS (Row Level Security)
- Usuários só veem seus próprios convites
- Só podem criar convites para suas próprias listas
- Só podem aceitar/rejeitar seus próprios convites

### Validações
- Verificação de usuário existente
- Prevenção de auto-convites
- Verificação de convites duplicados
- Validação de permissões

## Melhorias Futuras

1. **Notificações Push**: Implementar notificações em tempo real
2. **Histórico**: Página para ver convites aceitos/rejeitados
3. **Expiração**: Auto-expirar convites antigos
4. **Tipos de Permissão**: Diferentes níveis de acesso (leitura, edição)
5. **Convites em Lote**: Convidar múltiplos usuários de uma vez
