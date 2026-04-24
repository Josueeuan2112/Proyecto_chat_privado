import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_flutter/src/screens/group_chat_screen.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';
import 'package:whatsapp_flutter/src/service/socket_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/user_provider.dart';
import '../widgets/user_avatar.dart';

class GroupsScreen extends StatefulWidget {
  final int userId;
  final SocketService socketService;

  const GroupsScreen({required this.userId, required this.socketService});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // CARGAR GRUPOS DEL USUARIO
  Future<void> _loadGroups() async {
    setState(() {
      isLoading = true;
    });

    final resultado = await _apiService.getUserGroups();

    if (mounted) {
      setState(() {
        groups = resultado;
        isLoading = false;
      });
    }

    print('✅ Grupos cargados: ${groups.length}');
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    List<int> selectedMemberIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Crear Nuevo Grupo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo: Nombre
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del grupo *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.group, color: AppColors.primaryBlue),
                  ),
                ),
                SizedBox(height: 16),

                // Campo: Descripción
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.description,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),

                // Sección: Seleccionar miembros
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Miembros seleccionados: ${selectedMemberIds.length}',
                        style: AppTextStyles.caption,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await _showSelectMembersModal(
                            selectedMemberIds,
                          );
                          if (result != null) {
                            setState(() {
                              selectedMemberIds = result;
                            });
                          }
                        },
                        icon: Icon(Icons.person_add),
                        label: Text('Seleccionar miembros'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ingresa un nombre para el grupo')),
                  );
                  return;
                }

                if (selectedMemberIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selecciona al menos un miembro')),
                  );
                  return;
                }

                print('👥 Creando grupo: ${nameController.text}');
                print('👤 Miembros: $selectedMemberIds');

                final result = await _apiService.createGroup(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  memberIds: selectedMemberIds,
                );

                if (result['success']) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Grupo creado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                    _loadGroups();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${result['error']}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  // MODAL PARA SELECCIONAR MIEMBROS
  Future<List<int>?> _showSelectMembersModal(List<int> initialSelected) async {
    return showDialog<List<int>>(
      context: context,
      builder: (context) => _SelectMembersModal(
        apiService: _apiService,
        userId: widget.userId,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('Grupos', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: AppColors.primaryBlue),
            onPressed: _showCreateGroupDialog,
            tooltip: 'Crear nuevo grupo',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
              ),
            )
          : groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes grupos aún',
                    style: AppTextStyles.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crea uno haciendo clic en el botón +',
                    style: AppTextStyles.caption,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: Icon(Icons.add),
                    label: Text('Crear Grupo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final groupName = group['name'] ?? 'Grupo sin nombre';
                final groupId = group['id'];
                final adminId = group['admin_id'];
                final isAdmin = adminId == widget.userId;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(
                                groupId: groupId,
                                groupName: groupName,
                                currentUserId: widget.userId,
                                socketService: widget.socketService,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // ICONO DEL GRUPO
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppColors.buttonGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),

                              // INFORMACIÓN DEL GRUPO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupName,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      isAdmin ? 'Eres el admin' : 'Miembro',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),

                              // MENÚ DE OPCIONES
                              if (isAdmin)
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: AppColors.primaryBlue,
                                  ),
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_add,
                                            color: AppColors.primaryBlue,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Agregar miembro'),
                                        ],
                                      ),
                                      value: 'add',
                                    ),
                                    PopupMenuItem<String>(
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 12),
                                          Text(
                                            'Eliminar grupo',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      value: 'delete',
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'add') {
                                      print('Agregar miembro a: $groupName');
                                      // TODO: Implementar agregar miembro
                                    } else if (value == 'delete') {
                                      _showDeleteGroupDialog(
                                        groupId,
                                        groupName,
                                      );
                                    }
                                  },
                                )
                              else
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primaryBlue,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // MOSTRAR CONFIRMACIÓN PARA ELIMINAR GRUPO
  void _showDeleteGroupDialog(int groupId, String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Grupo'),
        content: Text(
          '¿Estás seguro que quieres eliminar el grupo "$groupName"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              print('🗑️ Eliminando grupo: $groupName');

              final result = await _apiService.deleteGroup(groupId);

              if (mounted) {
                Navigator.pop(context);

                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Grupo eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadGroups();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result['error']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// WIDGET MODAL PARA SELECCIONAR MIEMBROS
class _SelectMembersModal extends StatefulWidget {
  final ApiService apiService;
  final int userId;
  final List<int> initialSelected;

  const _SelectMembersModal({
    required this.apiService,
    required this.userId,
    required this.initialSelected,
  });

  @override
  State<_SelectMembersModal> createState() => _SelectMembersModalState();
}

class _SelectMembersModalState extends State<_SelectMembersModal> {
  late List<int> selectedMembers;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedMembers = List.from(widget.initialSelected);
    _loadUsers();
    searchController.addListener(_filterUsers);
  }

  // CARGAR USUARIOS
  Future<void> _loadUsers() async {
    final users = await widget.apiService.getUsers();

    if (mounted) {
      setState(() {
        // Filtrar: no mostrar al usuario actual
        allUsers = users.where((user) => user['id'] != widget.userId).toList();
        filteredUsers = List.from(allUsers);
        isLoading = false;
      });
    }

    print('✅ ${allUsers.length} usuarios cargados');
  }

  // FILTRAR USUARIOS POR BÚSQUEDA
  void _filterUsers() {
    final query = searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(allUsers);
      } else {
        filteredUsers = allUsers
            .where(
              (user) =>
                  user['username'].toString().toLowerCase().contains(query) ||
                  user['email'].toString().toLowerCase().contains(query),
            )
            .toList();
      }
    });

    print('🔍 ${filteredUsers.length} usuarios encontrados');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seleccionar Miembros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${selectedMembers.length} seleccionados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BUSCADOR
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
          ),

          // LISTA DE USUARIOS
          if (isLoading)
            Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
              ),
            )
          else if (filteredUsers.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay usuarios disponibles',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final userId = user['id'];
                  final username = user['username'];
                  final email = user['email'];
                  final isSelected = selectedMembers.contains(userId);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedMembers.add(userId);
                          print('✅ Usuario $username agregado');
                        } else {
                          selectedMembers.remove(userId);
                          print('❌ Usuario $username removido');
                        }
                      });
                    },
                    title: Text(username),
                    subtitle: Text(email),
                    activeColor: AppColors.primaryBlue,
                  );
                },
              ),
            ),

          // BOTONES DE ACCIÓN
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selectedMembers);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: Text('Confirmar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
