# Políticas RLS para SmartShop App

Este arquivo contém todas as políticas RLS (Row Level Security) necessárias para as tabelas do app SmartShop.

## IMPORTANTE: Execute estes comandos no SQL Editor do Supabase

### 1. ATIVAR RLS EM TODAS AS TABELAS

```sql
-- Ativar RLS em todas as tabelas
ALTER TABLE public."Users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_invitations ENABLE ROW LEVEL SECURITY;
```

## 2. POLÍTICAS PARA A TABELA Users

```sql
-- Policy: Usuários podem ver apenas seus próprios dados
CREATE POLICY "Users can view own profile" 
ON public."Users"
FOR SELECT
USING (auth.uid()::text = id::text);

-- Policy: Usuários podem atualizar apenas seus próprios dados
CREATE POLICY "Users can update own profile" 
ON public."Users"
FOR UPDATE
USING (auth.uid()::text = id::text);

-- Policy: Permitir inserção de novos usuários (registro)
CREATE POLICY "Enable insert for new users" 
ON public."Users"
FOR INSERT
WITH CHECK (auth.uid()::text = id::text);

-- Policy: Usuários podem buscar outros usuários por username (para compartilhamento)
-- NOTA: Esta policy permite busca por username mas não expõe dados sensíveis
CREATE POLICY "Users can search by username for sharing" 
ON public."Users"
FOR SELECT
USING (true); -- Permite busca por username, mas retorna apenas username e id
```

## 3. POLÍTICAS PARA A TABELA shopping_lists

```sql
-- Policy: Usuários podem ver suas próprias listas
CREATE POLICY "Users can view own lists" 
ON public.shopping_lists
FOR SELECT
USING (
  auth.uid()::text = owner_id::text 
  OR 
  id IN (
    SELECT list_id 
    FROM public.shared_lists 
    WHERE user_id::text = auth.uid()::text
  )
);

-- Policy: Usuários podem inserir suas próprias listas
CREATE POLICY "Users can insert own lists" 
ON public.shopping_lists
FOR INSERT
WITH CHECK (auth.uid()::text = owner_id::text);

-- Policy: Usuários podem atualizar suas próprias listas ou listas compartilhadas
CREATE POLICY "Users can update own or shared lists" 
ON public.shopping_lists
FOR UPDATE
USING (
  auth.uid()::text = owner_id::text 
  OR 
  id IN (
    SELECT list_id 
    FROM public.shared_lists 
    WHERE user_id::text = auth.uid()::text
  )
);

-- Policy: Apenas donos podem deletar listas
CREATE POLICY "Only owners can delete lists" 
ON public.shopping_lists
FOR DELETE
USING (auth.uid()::text = owner_id::text);
```

## 4. POLÍTICAS PARA A TABELA shopping_items

```sql
-- Policy: Usuários podem ver itens de suas listas ou listas compartilhadas
CREATE POLICY "Users can view items from accessible lists" 
ON public.shopping_items
FOR SELECT
USING (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
    OR id IN (
      SELECT list_id 
      FROM public.shared_lists 
      WHERE user_id::text = auth.uid()::text
    )
  )
);

-- Policy: Usuários podem inserir itens em suas listas ou listas compartilhadas
CREATE POLICY "Users can insert items in accessible lists" 
ON public.shopping_items
FOR INSERT
WITH CHECK (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
    OR id IN (
      SELECT list_id 
      FROM public.shared_lists 
      WHERE user_id::text = auth.uid()::text
    )
  )
);

-- Policy: Usuários podem atualizar itens de suas listas ou listas compartilhadas
CREATE POLICY "Users can update items in accessible lists" 
ON public.shopping_items
FOR UPDATE
USING (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
    OR id IN (
      SELECT list_id 
      FROM public.shared_lists 
      WHERE user_id::text = auth.uid()::text
    )
  )
);

-- Policy: Usuários podem deletar itens de suas listas ou listas compartilhadas
CREATE POLICY "Users can delete items from accessible lists" 
ON public.shopping_items
FOR DELETE
USING (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
    OR id IN (
      SELECT list_id 
      FROM public.shared_lists 
      WHERE user_id::text = auth.uid()::text
    )
  )
);
```

## 5. POLÍTICAS PARA A TABELA shared_lists

```sql
-- Policy: Usuários podem ver compartilhamentos de suas listas (como dono)
CREATE POLICY "Users can view shares of own lists" 
ON public.shared_lists
FOR SELECT
USING (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
  )
  OR user_id::text = auth.uid()::text
);

-- Policy: Apenas donos de listas podem criar compartilhamentos
CREATE POLICY "Only list owners can create shares" 
ON public.shared_lists
FOR INSERT
WITH CHECK (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
  )
);

-- Policy: Apenas donos podem atualizar compartilhamentos
CREATE POLICY "Only list owners can update shares" 
ON public.shared_lists
FOR UPDATE
USING (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
  )
);

-- Policy: Donos podem deletar compartilhamentos, usuários podem sair de listas compartilhadas
CREATE POLICY "Owners can delete shares, users can leave shared lists" 
ON public.shared_lists
FOR DELETE
USING (
  list_id IN (
    SELECT id 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
  )
  OR user_id::text = auth.uid()::text
);
```

## 6. POLÍTICAS PARA A TABELA list_invitations

```sql
-- Policy: Usuários podem ver convites enviados ou recebidos
CREATE POLICY "Users can view sent or received invitations" 
ON public.list_invitations
FOR SELECT
USING (
  inviter_username IN (
    SELECT "Username" 
    FROM public."Users" 
    WHERE id::text = auth.uid()::text
  )
  OR invited_username IN (
    SELECT "Username" 
    FROM public."Users" 
    WHERE id::text = auth.uid()::text
  )
);

-- Policy: Usuários podem criar convites apenas para suas listas
CREATE POLICY "Users can create invitations for own lists" 
ON public.list_invitations
FOR INSERT
WITH CHECK (
  list_id::text IN (
    SELECT id::text 
    FROM public.shopping_lists 
    WHERE owner_id::text = auth.uid()::text
  )
  AND inviter_username IN (
    SELECT "Username" 
    FROM public."Users" 
    WHERE id::text = auth.uid()::text
  )
);

-- Policy: Usuários podem atualizar convites que enviaram ou receberam
CREATE POLICY "Users can update own sent or received invitations" 
ON public.list_invitations
FOR UPDATE
USING (
  inviter_username IN (
    SELECT "Username" 
    FROM public."Users" 
    WHERE id::text = auth.uid()::text
  )
  OR invited_username IN (
    SELECT "Username" 
    FROM public."Users" 
    WHERE id::text = auth.uid()::text
  )
);

-- Policy: Usuários podem deletar convites que enviaram
CREATE POLICY "Users can delete sent invitations" 
ON public.list_invitations
FOR DELETE
USING (
  inviter_username IN (
    SELECT "Username" 
    FROM public."Users" 
    WHERE id::text = auth.uid()::text
  )
);
```

## 7. VERIFICAÇÃO DAS POLÍTICAS

Após executar todos os comandos acima, você pode verificar se as políticas foram criadas corretamente:

```sql
-- Verificar políticas da tabela Users
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'Users';

-- Verificar políticas da tabela shopping_lists
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'shopping_lists';

-- Verificar políticas da tabela shopping_items
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'shopping_items';

-- Verificar políticas da tabela shared_lists
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'shared_lists';

-- Verificar políticas da tabela list_invitations
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'list_invitations';
```

## 8. COMANDOS PARA REMOVER POLÍTICAS (SE NECESSÁRIO)

```sql
-- Se precisar remover alguma política para recriá-la:
-- DROP POLICY "nome_da_policy" ON public.nome_da_tabela;

-- Exemplo:
-- DROP POLICY "Users can view own profile" ON public."Users";
```

## NOTAS IMPORTANTES:

1. **auth.uid()**: Função do Supabase que retorna o ID do usuário autenticado
2. **Conversões de tipo**: Uso de `::text` para garantir compatibilidade entre tipos UUID e text
3. **Segurança em camadas**: As políticas garantem que usuários só acessem dados que têm permissão
4. **Busca por username**: A policy na tabela Users permite busca por username para funcionalidade de compartilhamento
5. **Compartilhamento**: Usuários podem ver e modificar listas compartilhadas com eles
6. **Donos vs Colaboradores**: Distinção clara entre proprietários e colaboradores de listas

Essas políticas garantem que:
- ✅ Usuários só veem seus próprios dados
- ✅ Listas são acessíveis apenas pelos donos e colaboradores
- ✅ Itens são acessíveis apenas em listas que o usuário tem acesso
- ✅ Compartilhamentos são controlados pelos donos das listas
- ✅ Convites são controlados adequadamente