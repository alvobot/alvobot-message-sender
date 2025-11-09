<template>
  <div
    class="messenger-flow-builder"
    :style="{
      height: content?.height || '100%',
      background: content?.backgroundColor || '#f5f5f5',
      minHeight: '400px',
      position: 'relative'
    }"
  >


    <!-- Vue Flow Canvas -->
    <VueFlow
      :nodes="nodes"
      :edges="edges"
      :nodes-draggable="content?.enableEdit && !isSpacePressed"
      :nodes-connectable="content?.enableEdit"
      :elements-selectable="content?.enableEdit"
      :is-valid-connection="isValidConnection"
      :connect-on-drop="true"
      :pan-on-drag="isSpacePressed ? true : [2]"
      :pan-on-scroll="false"
      :selection-key-code="isSpacePressed ? null : true"
      :multi-selection-key-code="'Shift'"
      :delete-key-code="null"
      :zoom-on-scroll="true"
      :zoom-on-pinch="true"
      :zoom-on-double-click="false"
      :selection-mode="'partial'"
      :min-zoom="0.2"
      :max-zoom="4"
      :default-edge-options="defaultEdgeOptions"
      :connection-line-type="ConnectionLineType.SmoothStep"
      :connection-line-style="connectionLineStyle"
      :class="['messenger-flow', { 'is-panning': isSpacePressed }]"
      @nodes-change="onNodesChange"
      @edges-change="onEdgesChange"
      @connect="onConnect"
      @connect-start="onConnectStart"
      @connect-end="onConnectEnd"
      @drop="onDrop"
      @node-drag="onNodeDrag"
      @node-drag-stop="onNodeDragStop"
      @dragover="onDragOver"
      @pane-click="onPaneClick"
    >
      <!-- Background with pointer-events disabled -->
      <Background
        pattern="dots"
        :gap="20"
        :size="2"
        :color="content?.accentColor || '#3b82f6'"
        :opacity="0.1"
        style="pointer-events: none;"
      />

      <!-- Auto-Layout Button -->
      <button
        v-if="content?.enableEdit"
        class="auto-layout-button"
        @click="autoLayout"
        title="Organizar nós automaticamente"
      >
        <Wand2 :size="20" />
      </button>

      <!-- Controls -->
      <Controls v-if="content?.enableEdit" :show-interactive="false" />

      <!-- Refresh Button (custom control) -->
      <button
        v-if="content?.enableEdit"
        class="refresh-button"
        @click="refreshCanvas"
        title="Atualizar visualização"
        aria-label="Atualizar canvas"
      >
        <RefreshCw :size="16" />
      </button>

      <!-- Navigation Hint (shown when canvas is empty) -->
      <div v-if="content?.enableEdit && nodes.length === 0" class="navigation-hint">
        💡 Dica: Pressione <kbd>SPACE</kbd> + arrastar para navegar pelo canvas
      </div>

      <!-- Custom Edge with Delete Button -->
      <template #edge-smoothstep="edgeProps">
        <g
          class="custom-edge-wrapper"
          @mouseenter="handleEdgeHover(edgeProps.id, true)"
          @mouseleave="handleEdgeHover(edgeProps.id, false)"
        >
          <!-- Use SmoothStepEdge component for proper path rendering -->
          <SmoothStepEdge
            :id="edgeProps.id"
            :source-x="edgeProps.sourceX"
            :source-y="edgeProps.sourceY"
            :target-x="edgeProps.targetX"
            :target-y="edgeProps.targetY"
            :source-position="edgeProps.sourcePosition"
            :target-position="edgeProps.targetPosition"
            :marker-end="edgeProps.markerEnd"
            :style="{
              stroke: edgeProps.selected ? '#3b82f6' : '#b1b1b7',
              strokeWidth: edgeProps.selected ? 3 : 2,
              strokeDasharray: '5',
              animation: 'connectionLineDash 0.5s linear infinite'
            }"
            :label="edgeProps.label"
          />

          <!-- Delete button in center of edge -->
          <foreignObject
            v-if="content?.enableEdit && (hoveredEdge === edgeProps.id || edgeProps.selected)"
            :x="(edgeProps.sourceX + edgeProps.targetX) / 2 - 12"
            :y="(edgeProps.sourceY + edgeProps.targetY) / 2 - 12"
            width="24"
            height="24"
            class="edge-delete-wrapper"
            style="overflow: visible; pointer-events: all;"
          >
            <div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center;">
              <button
                class="edge-delete-button"
                @click.stop="() => { removeEdges([edgeProps.id]); hoveredEdge = null; emitFlowChanged(); }"
                @mousedown.stop
                title="Deletar conexão"
              >
                <X :size="12" />
              </button>
            </div>
          </foreignObject>
        </g>
      </template>

      <!-- Custom Connection Line (animated while dragging) -->
      <template #connection-line="connectionLineProps">
        <g>
          <path
            :d="getConnectionPath(connectionLineProps.sourceX, connectionLineProps.sourceY, connectionLineProps.targetX, connectionLineProps.targetY, connectionLineProps.sourcePosition, connectionLineProps.targetPosition)"
            class="vue-flow__connection-path animated"
            fill="none"
            :stroke="getConnectionStrokeColor(connectionLineProps.targetX, connectionLineProps.targetY)"
            :stroke-width="2.5"
          />
          <circle
            :cx="connectionLineProps.targetX"
            :cy="connectionLineProps.targetY"
            fill="#fff"
            :r="3"
            :stroke="getConnectionStrokeColor(connectionLineProps.targetX, connectionLineProps.targetY)"
            :stroke-width="1.5"
          />
        </g>
      </template>

      <!-- Custom Node Templates -->
      <template #node-start="{ id, selected }">
        <div class="messenger-node start-node" :class="{ selected }">
          <div class="node-header">
            <div class="node-icon"><Rocket :size="20" /></div>
            <div class="node-title">Início</div>
            <!-- Start node não tem botões de editar/deletar - é protegido -->
          </div>
          <div class="node-content">
            <p>Ponto de partida do fluxo</p>
          </div>
          <Handle type="source" :position="Position.Right" />
          <button v-if="content?.enableEdit" class="node-add-child" @click="showChildNodeMenu(id, $event)" title="Adicionar nó filho">
            <Plus :size="14" />
          </button>
        </div>
      </template>

      <template #node-text="{ data, id, selected }">
        <div class="messenger-node text-node" :class="{ selected }" @dblclick="editNode(id)">
          <div class="node-header">
            <div class="node-icon"><MessageSquare :size="20" /></div>
            <div class="node-title">Mensagem de Texto</div>
            <AlertTriangle
              v-if="validationState.get(id)?.hasWarning || validationState.get(id)?.hasError"
              :size="16"
              class="node-validation-icon"
              :class="{ 'error': validationState.get(id)?.hasError, 'warning': validationState.get(id)?.hasWarning }"
              @mouseenter="showTooltip(id, $event)"
              @mouseleave="hideTooltip"
            />
            <button v-if="content?.enableEdit" @click="showActionsMenu(id, $event)" class="node-actions" title="Ações" aria-label="Menu de ações">
              <MoreVertical :size="14" />
            </button>
            <button v-if="content?.enableEdit" @click="editNode(id, data)" class="node-edit" aria-label="Editar nó"><Edit :size="14" /></button>
            <button v-if="content?.enableEdit" @click="deleteNode(id)" class="node-delete" aria-label="Deletar nó">×</button>
          </div>
          <div class="node-content">
            <p class="node-text" v-text="data.text || 'Digite sua mensagem...'"></p>
            <div v-if="data.buttons && data.buttons.length > 0" class="node-buttons">
              <div
                v-for="(button, index) in data.buttons"
                :key="button.id"
                class="button-preview"
              >
                <Circle :size="12" /> {{ button.label || `Botão ${index + 1}` }}
              </div>
            </div>
          </div>
          <Handle type="target" :position="Position.Left" />
          <Handle type="source" :position="Position.Right" />
          <button v-if="content?.enableEdit" class="node-add-child" @click="showChildNodeMenu(id, $event)" title="Adicionar nó filho">
            <Plus :size="14" />
          </button>
        </div>
      </template>

      <template #node-card="{ data, id, selected }">
        <div class="messenger-node card-node" :class="{ selected }" @dblclick="editNode(id)">
          <div class="node-header">
            <div class="node-icon"><ImageIcon :size="20" /></div>
            <div class="node-title">Mensagem com Imagem</div>
            <AlertTriangle
              v-if="validationState.get(id)?.hasWarning || validationState.get(id)?.hasError"
              :size="16"
              class="node-validation-icon"
              :class="{ 'error': validationState.get(id)?.hasError, 'warning': validationState.get(id)?.hasWarning }"
              @mouseenter="showTooltip(id, $event)"
              @mouseleave="hideTooltip"
            />
            <button v-if="content?.enableEdit" @click="showActionsMenu(id, $event)" class="node-actions" title="Ações" aria-label="Menu de ações">
              <MoreVertical :size="14" />
            </button>
            <button v-if="content?.enableEdit" @click="editNode(id, data)" class="node-edit" aria-label="Editar nó"><Edit :size="14" /></button>
            <button v-if="content?.enableEdit" @click="deleteNode(id)" class="node-delete" aria-label="Deletar nó">×</button>
          </div>
          <div class="node-content">
            <div class="card-preview">
              <div v-if="data.imageUrl" class="card-image" :style="{
                aspectRatio: data.imageAspectRatio === 'square' ? '1 / 1' : '1.91 / 1'
              }">
                <img :src="data.imageUrl" alt="Card image" style="width: 100%; height: 100%; object-fit: cover; border-radius: calc(var(--radius) - 4px);" />
              </div>
              <div v-else class="card-image-placeholder" :style="{
                aspectRatio: data.imageAspectRatio === 'square' ? '1 / 1' : '1.91 / 1'
              }"><ImageIcon :size="16" /> Imagem</div>
              <div class="card-title" v-text="data.title || 'Título do Card'"></div>
              <div v-if="data.subtitle" class="card-desc" v-text="data.subtitle"></div>
              <div v-if="data.url" class="card-url"><Link :size="14" /> {{ data.url.substring(0, 30) }}...</div>
              <div v-if="data.buttons && data.buttons.length > 0" class="node-buttons">
                <div
                  v-for="(button, index) in data.buttons"
                  :key="button.id"
                  class="button-preview"
                >
                  <Circle :size="12" /> {{ button.label || `Botão ${index + 1}` }}
                </div>
              </div>
            </div>
          </div>
          <Handle type="target" :position="Position.Left" />
          <Handle type="source" :position="Position.Right" />
          <button v-if="content?.enableEdit" class="node-add-child" @click="showChildNodeMenu(id, $event)" title="Adicionar nó filho">
            <Plus :size="14" />
          </button>
        </div>
      </template>

      <template #node-wait="{ data, id, selected }">
        <div class="messenger-node wait-node" :class="{ selected }" @dblclick="editNode(id)">
          <div class="node-header">
            <div class="node-icon"><Clock :size="20" /></div>
            <div class="node-title">Aguardar</div>
            <AlertTriangle
              v-if="validationState.get(id)?.hasWarning || validationState.get(id)?.hasError"
              :size="16"
              class="node-validation-icon"
              :class="{ 'error': validationState.get(id)?.hasError, 'warning': validationState.get(id)?.hasWarning }"
              @mouseenter="showTooltip(id, $event)"
              @mouseleave="hideTooltip"
            />
            <button v-if="content?.enableEdit" @click="showActionsMenu(id, $event)" class="node-actions" title="Ações" aria-label="Menu de ações">
              <MoreVertical :size="14" />
            </button>
            <button v-if="content?.enableEdit" @click="editNode(id, data)" class="node-edit" aria-label="Editar nó"><Edit :size="14" /></button>
            <button v-if="content?.enableEdit" @click="deleteNode(id)" class="node-delete" aria-label="Deletar nó">×</button>
          </div>
          <div class="node-content">
            <p>Aguardar {{ data.duration || '5' }} {{
              data.timeUnit === 'minutes' ? 'minuto(s)' :
              data.timeUnit === 'hours' ? 'hora(s)' :
              data.timeUnit === 'days' ? 'dia(s)' :
              'segundo(s)'
            }}</p>
          </div>
          <Handle type="target" :position="Position.Left" />
          <Handle type="source" :position="Position.Right" />
          <button v-if="content?.enableEdit" class="node-add-child" @click="showChildNodeMenu(id, $event)" title="Adicionar nó filho">
            <Plus :size="14" />
          </button>
        </div>
      </template>

<template #node-traffic="{ data, id, selected }">
  <div class="messenger-node traffic-node" :class="{ selected }" @dblclick="editNode(id)" :style="{ minHeight: `${80 + (data.branches?.length || 2) * 30}px` }">
    <div class="node-header">
      <div class="node-icon"><GitBranch :size="20" /></div>
      <div class="node-title">Divisor de Tráfego</div>
      <AlertTriangle
        v-if="validationState.get(id)?.hasWarning || validationState.get(id)?.hasError"
        :size="16"
        class="node-validation-icon"
        :class="{ 'error': validationState.get(id)?.hasError, 'warning': validationState.get(id)?.hasWarning }"
        @mouseenter="showTooltip(id, $event)"
        @mouseleave="hideTooltip"
      />
      <button v-if="content?.enableEdit" @click="showActionsMenu(id, $event)" class="node-actions" title="Ações" aria-label="Menu de ações">
        <MoreVertical :size="14" />
      </button>
      <button v-if="content?.enableEdit" @click="editNode(id, data)" class="node-edit" aria-label="Editar nó"><Edit :size="14" /></button>
      <button v-if="content?.enableEdit" @click="deleteNode(id)" class="node-delete" aria-label="Deletar nó">×</button>
    </div>
    <div class="node-content">
      <div class="traffic-branches">
        <div
          v-for="(branch, index) in (data.branches || [])"
          :key="branch.id"
          class="branch-preview"
          :style="{ borderLeftColor: getBranchColor(index) }"
        >
          <span class="branch-dot" :style="{ background: getBranchColor(index) }"></span>
          {{ branch.label }} ({{ branch.percentage }}%)
        </div>
      </div>
    </div>
    <!-- Input handle -->
    <Handle
      type="target"
      :position="Position.Left"
      :style="{
        top: '50%',
        transform: 'translateY(-50%)'
      }"
    />
    <!-- Multiple output handles - one for each branch -->
    <Handle
      v-for="(branch, index) in (data.branches || [])"
      :key="`handle-${branch.id}`"
      :id="id ? `${id}-output-${index}` : `output-${index}`"
      type="source"
      :position="Position.Right"
      :style="{
        top: `${80 + (index * 39)}px`,
        background: getBranchColor(index),
        border: '2px solid white',
        width: `${UI_SIZES.HANDLE_SMALL}px`,
        height: `${UI_SIZES.HANDLE_SMALL}px`
      }"
    />
  </div>
</template>

      <!-- Error Node Template (for unknown/deprecated node types) -->
      <template #node-error="{ data, id, selected }">
        <div class="messenger-node error-node" :class="{ selected }">
          <div class="node-header">
            <div class="node-icon"><AlertTriangle :size="20" /></div>
            <div class="node-title">Tipo de Nó Inválido</div>
            <button v-if="content?.enableEdit" @click="deleteNode(id)" class="node-delete" aria-label="Deletar nó">×</button>
          </div>
          <div class="node-content">
            <div class="error-message">
              <p><strong>Tipo não reconhecido:</strong> <code>{{ data.originalType }}</code></p>
              <p class="error-help">Este tipo de nó não existe ou foi descontinuado.</p>
              <p class="error-action">Por favor, delete este nó e substitua por um tipo válido.</p>
            </div>
          </div>
          <!-- Input handle -->
          <Handle
            type="target"
            :position="Position.Left"
            :style="{
              top: '50%',
              transform: 'translateY(-50%)',
              background: '#ef4444'
            }"
          />
          <!-- Output handle -->
          <Handle
            type="source"
            :position="Position.Right"
            :style="{
              top: '50%',
              transform: 'translateY(-50%)',
              background: '#ef4444'
            }"
          />
        </div>
      </template>

      <!-- Helper Lines Canvas -->
      <canvas ref="helperLinesCanvasRef" class="helper-lines-canvas" />
    </VueFlow>

    <!-- Empty State -->
    <div v-if="content?.enableEdit && nodes.length === 0" class="empty-state">
      <div class="empty-state-content">
        <button class="empty-state-icon" @click="addNode(NodeTypes.START)" title="Adicionar primeiro passo">
          <Plus :size="48" />
        </button>
        <h3 class="empty-state-title">Adicione o primeiro passo...</h3>
        <p class="empty-state-description">Clique no botão acima ou arraste um componente do painel lateral</p>
      </div>
    </div>

    <!-- Components Dock -->
    <div v-if="content?.showDock && content?.enableEdit" class="components-dock" :class="{ 'collapsed': isDockCollapsed }">
      <button
        class="dock-toggle"
        @click="isDockCollapsed = !isDockCollapsed"
        :title="isDockCollapsed ? 'Expandir painel de componentes' : 'Retrair painel'"
        :aria-label="isDockCollapsed ? 'Expandir painel' : 'Retrair painel'"
        :aria-expanded="!isDockCollapsed"
      >
        <ChevronRight v-if="isDockCollapsed" :size="18" />
        <ChevronLeft v-else :size="18" />
      </button>

      <!-- Reusable component list -->
      <div class="dock-content">
        <div class="dock-items">
          <div
            v-for="componentType in availableComponents"
            :key="componentType.type"
            class="dock-item"
            draggable="true"
            @click="onDockItemClick(componentType.type, $event)"
            @dragstart="onDragStart(componentType.type, $event)"
            @dragend="onDragEnd"
            :title="isDockCollapsed ? `${componentType.title}: ${componentType.description || 'Clique para adicionar'}` : `Add ${componentType.title}`"
          >
            <component :is="componentType.icon" :size="20" />
            <span>{{ componentType.title }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Toolbar -->
    <div v-if="content?.showToolbar && content?.enableEdit" class="toolbar">
      <button class="toolbar-btn" @click="clearFlow" title="Clear Flow">
        <Trash2 :size="18" />
      </button>
      <button class="toolbar-btn" @click="saveFlow" title="Save Flow">
        <Save :size="18" />
      </button>
      <button class="toolbar-btn" @click="exportFlow" title="Export Flow">
        <Download :size="18" />
      </button>
      <button class="toolbar-btn" @click="importFlow" title="Import Flow">
        <Upload :size="18" />
      </button>
    </div>

    <!-- Child Node Selection Menu - Reuses dock structure EXACTLY -->
    <div
      v-if="childNodeMenu.visible"
      class="child-node-menu components-dock"
      :style="{
        position: 'fixed',
        left: `${childNodeMenu.x}px`,
        top: `${childNodeMenu.y}px`,
        zIndex: 10001
      }"
    >
      <div class="dock-content">
        <div class="dock-items">
          <div
            v-for="component in availableComponents"
            :key="component.type"
            class="dock-item"
            @click="createChildNode(component.type)"
            :title="`Add ${component.title}`"
          >
            <component :is="component.icon" :size="20" />
            <span>{{ component.title }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Overlay to close menu when clicking outside -->
    <div
      v-if="childNodeMenu.visible"
      class="child-node-menu-overlay"
      @click="closeChildNodeMenu"
    ></div>

    <!-- Node Actions Menu - Simple 3-dots menu -->
    <div
      v-if="actionsMenu.visible"
      class="actions-menu components-dock"
      :style="{
        position: 'fixed',
        left: `${actionsMenu.x}px`,
        top: `${actionsMenu.y}px`,
        zIndex: 10002
      }"
    >
      <div class="dock-content">
        <div class="dock-items">
          <!-- Duplicar: só aparece se NÃO for nó Start -->
          <div
            v-if="actionsMenuNode?.type !== NodeTypes.START"
            class="dock-item"
            @click="duplicateNode"
            title="Cria uma cópia do nó"
          >
            <Copy :size="16" />
            <span>Duplicar</span>
          </div>
          <!-- Deletar: só aparece se NÃO for nó Start -->
          <div
            v-if="actionsMenuNode?.type !== NodeTypes.START"
            class="dock-item"
            @click="deleteNode(actionsMenu.nodeId)"
            title="Deleta o nó"
          >
            <Trash2 :size="16" />
            <span>Deletar</span>
          </div>
          <!-- Se for Start, mostra mensagem informativa -->
          <div
            v-if="actionsMenuNode?.type === NodeTypes.START"
            class="dock-item disabled-item"
            title="O nó de início não pode ser duplicado ou deletado"
          >
            <AlertTriangle :size="16" />
            <span>Nó de início protegido</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Overlay to close actions menu when clicking outside -->
    <div
      v-if="actionsMenu.visible"
      class="actions-menu-overlay"
      @click="closeActionsMenu"
    ></div>

    <!-- Toast Notifications -->
    <div class="toast-container">
      <transition-group name="toast">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          class="toast"
          :class="`toast-${toast.type}`"
        >
          <div class="toast-icon">
            <AlertTriangle v-if="toast.type === ToastTypes.ERROR" :size="18" />
            <AlertTriangle v-else-if="toast.type === ToastTypes.WARNING" :size="18" />
            <Circle v-else-if="toast.type === ToastTypes.SUCCESS" :size="18" />
            <Circle v-else :size="18" />
          </div>
          <div class="toast-content">
            <div class="toast-title">{{ toast.title }}</div>
            <div v-if="toast.message" class="toast-message">{{ toast.message }}</div>
          </div>
          <button class="toast-close" @click="removeToast(toast.id)">×</button>
        </div>
      </transition-group>
    </div>

    <!-- Custom Dialog -->
    <div v-if="dialogState.isVisible" class="dialog-overlay" @click.self="closeDialog(false)">
      <div class="dialog">
        <div class="dialog-header">
          <AlertTriangle v-if="dialogState.type === 'confirm'" :size="24" class="dialog-icon warning" />
          <Circle v-else :size="24" class="dialog-icon info" />
          <h3>{{ dialogState.title }}</h3>
        </div>

        <div class="dialog-body">
          <p v-for="(line, index) in dialogState.message.split('\n')" :key="index" class="dialog-message">
            {{ line }}
          </p>
        </div>

        <div class="dialog-actions">
          <button v-if="dialogState.type === 'confirm'" @click="closeDialog(false)" class="dialog-btn dialog-btn-cancel">
            Cancelar
          </button>
          <button @click="closeDialog(true)" class="dialog-btn dialog-btn-confirm">
            {{ dialogState.type === 'confirm' ? 'Confirmar' : 'OK' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Validation Tooltip -->
    <div
      v-if="tooltipState.visible && tooltipState.nodeId"
      class="validation-tooltip"
      :style="{
        left: tooltipState.x + 'px',
        top: tooltipState.y + 'px'
      }"
    >
      <div
        v-for="(issue, index) in (validationState.get(tooltipState.nodeId)?.issues || [])"
        :key="index"
        class="tooltip-issue"
        :class="{ 'error': validationState.get(tooltipState.nodeId)?.hasError, 'warning': !validationState.get(tooltipState.nodeId)?.hasError }"
      >
        {{ issue }}
      </div>
    </div>

    <!-- Edit Sidebar -->
    <div v-if="editingSidebar.visible && content?.enableEdit" class="edit-sidebar">
      <div class="sidebar-header">
        <h3>Editar Nó</h3>
        <button @click="closeEditSidebar" class="close-btn">×</button>
      </div>

      <div class="sidebar-content">
        <div v-if="editingSidebar.node?.type === NodeTypes.TEXT" class="edit-form">
          <div class="form-group">
            <label>Tipo da Mensagem:</label>
            <select v-model="editingSidebar.data.messageType">
              <option value="ACCOUNT_UPDATE">Account Update</option>
            </select>
          </div>

          <div class="form-group">
            <label>Texto da Mensagem:</label>
            <textarea
              v-model="editingSidebar.data.text"
              placeholder="Digite sua mensagem..."
              rows="4"
            />
          </div>

          <div class="form-group">
            <label>Botões:</label>
            <div class="buttons-editor">
              <div
                v-for="(button, index) in editingSidebar.data.buttons"
                :key="button.id"
                class="button-editor"
              >
                <div class="button-row">
                  <input
                    v-model="button.label"
                    placeholder="Label do botão"
                    class="button-input"
                  />
                  <select v-model="button.action" class="button-action">
                    <option value="send_message">Send Message</option>
                    <option value="open_website">Open Website</option>
                  </select>
                  <button @click="removeButton(index)" class="remove-btn">×</button>
                </div>
                <input
                  v-if="button.action === 'send_message'"
                  v-model="button.message"
                  placeholder="Mensagem a ser enviada"
                  class="button-input"
                />
                <input
                  v-if="button.action === 'open_website'"
                  v-model="button.url"
                  placeholder="URL do website"
                  class="button-input"
                />
              </div>
              <button @click="addButton" class="add-button">+ Adicionar Botão</button>
            </div>
          </div>
        </div>

        <div v-else-if="editingSidebar.node?.type === NodeTypes.CARD" class="edit-form">
          <div class="form-group">
            <label>Tipo da Mensagem:</label>
            <select v-model="editingSidebar.data.messageType">
              <option value="ACCOUNT_UPDATE">Messenger - Account Update</option>
            </select>
          </div>

          <div class="form-group" :class="{ 'has-error': !editingSidebar.data.title }">
            <label>Título (obrigatório):</label>
            <input
              v-model="editingSidebar.data.title"
              placeholder="Título do card"
              required
              :class="{ 'input-error': !editingSidebar.data.title }"
            />
            <span v-if="!editingSidebar.data.title" class="field-error">Este campo é obrigatório</span>
          </div>
          <div class="form-group">
            <label>Subtítulo (opcional):</label>
            <input
              v-model="editingSidebar.data.subtitle"
              placeholder="Subtítulo do card"
            />
          </div>
          <div class="form-group">
            <label>Imagem:</label>
            <input
              type="file"
              accept="image/*"
              @change="uploadImage"
              class="file-input"
            />
            <input
              v-model="editingSidebar.data.imageUrl"
              placeholder="URL da imagem (ou faça upload acima)"
              class="image-url-input"
            />
            <div v-if="editingSidebar.data.imageUrl" class="image-preview">
              <img :src="editingSidebar.data.imageUrl" alt="Preview" style="max-width: 100%; max-height: 100px;" />
            </div>
          </div>
          <div class="form-group">
            <label>Formato da Imagem:</label>
            <select v-model="editingSidebar.data.imageAspectRatio">
              <option value="square">Quadrado (1:1) - Recomendado</option>
              <option value="horizontal">Horizontal (1.91:1) - Padrão Facebook</option>
            </select>
            <small style="color: #6b7280; font-size: 12px; display: block; margin-top: 4px;">
              💡 Quadrado (1:1) funciona melhor no mobile
            </small>
          </div>
          <div class="form-group">
            <label>URL do Card:</label>
            <input
              v-model="editingSidebar.data.url"
              placeholder="https://example.com"
            />
          </div>

          <div class="form-group">
            <label>Botões:</label>
            <div class="buttons-editor">
              <div
                v-for="(button, index) in editingSidebar.data.buttons"
                :key="button.id"
                class="button-editor"
              >
                <div class="button-row">
                  <input
                    v-model="button.label"
                    placeholder="Label do botão"
                    class="button-input"
                  />
                  <select v-model="button.action" class="button-action">
                    <option value="send_message">Send Message</option>
                    <option value="open_website">Open Website</option>
                  </select>
                  <button @click="removeButton(index)" class="remove-btn">×</button>
                </div>
                <input
                  v-if="button.action === 'send_message'"
                  v-model="button.message"
                  placeholder="Mensagem a ser enviada"
                  class="button-input"
                />
                <input
                  v-if="button.action === 'open_website'"
                  v-model="button.url"
                  placeholder="URL do website"
                  class="button-input"
                />
              </div>
              <button @click="addButton" class="add-button">+ Adicionar Botão</button>
            </div>
          </div>
        </div>

        <div v-else-if="editingSidebar.node?.type === NodeTypes.TRAFFIC" class="edit-form">
          <div class="form-group">
            <label>Divisão de Tráfego:</label>
            <div class="traffic-editor">
              <div
                v-for="(branch, index) in editingSidebar.data.branches"
                :key="branch.id"
                class="branch-editor"
              >
                <div class="branch-row">
                  <input
                    v-model="branch.label"
                    placeholder="Nome da opção"
                    class="branch-input"
                  />
                  <input
                    type="number"
                    v-model.number="branch.percentage"
                    min="1"
                    max="100"
                    placeholder="50"
                    class="percentage-input"
                  />
                  <span class="percentage-sign">%</span>
                  <button @click="removeBranch(index)" class="remove-btn">×</button>
                </div>
              </div>
              <div class="traffic-actions">
                <button @click="addBranch" class="add-button">+ Adicionar Opção</button>
                <button
                  @click="distributeEquallyBranches"
                  class="distribute-button"
                  :disabled="editingSidebar.data.branches.length === 0"
                  title="Distribuir percentuais igualmente entre todas as opções"
                >
                  ⚖️ Distribuir Igualmente
                </button>
              </div>
              <div class="percentage-total" :class="{ 'valid': getTotalPercentage() === 100, 'invalid': getTotalPercentage() !== 100 }">
                Total: {{ getTotalPercentage() }}%
                <span v-if="getTotalPercentage() === 100" class="success-badge">✓ Válido</span>
                <span v-else class="warning-badge">⚠️ Deve somar 100%</span>
              </div>
            </div>
          </div>
        </div>

        <div v-else-if="editingSidebar.node?.type === NodeTypes.WAIT" class="edit-form">
          <div class="form-group">
            <label>Tempo de espera:</label>
            <div style="display: flex; gap: 10px;">
              <input
                type="number"
                v-model.number="editingSidebar.data.duration"
                min="1"
                placeholder="5"
                style="flex: 1;"
              />
              <select v-model="editingSidebar.data.timeUnit" style="flex: 1;">
                <option value="seconds">Segundos</option>
                <option value="minutes">Minutos</option>
                <option value="hours">Horas</option>
                <option value="days">Dias</option>
              </select>
            </div>
          </div>
        </div>

        <div class="sidebar-actions">
          <button class="save-btn" @click="saveNodeEdit">Salvar</button>
          <button class="cancel-btn" @click="closeEditSidebar">Cancelar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, watch, onMounted, onUnmounted, nextTick } from 'vue';
import { v4 as uuidv4 } from 'uuid';
import {
  VueFlow,
  useVueFlow,
  MarkerType,
  Handle,
  Position,
  ConnectionLineType,
  SmoothStepEdge,
  getBezierPath,
  applyNodeChanges,
  applyEdgeChanges
} from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import {
  Rocket, MessageSquare, Clock, GitBranch,
  Edit, Circle, Image as ImageIcon, Link,
  Trash2, Save, Download, Upload, ChevronLeft, ChevronRight, Plus, X, AlertTriangle, Wand2,
  Copy, MoreVertical, RefreshCw
} from 'lucide-vue-next';

export default {
  components: {
    VueFlow,
    Background,
    Controls,
    Handle,
    SmoothStepEdge,
    // Lucide icons
    Trash2,
    Save,
    Download,
    Upload,
    Rocket,
    MessageSquare,
    GitBranch,
    Clock,
    Edit,
    Circle,
    ImageIcon,
    Link,
    ChevronLeft,
    ChevronRight,
    Plus,
    X,
    AlertTriangle,
    Wand2,
    Copy,
    MoreVertical,
    RefreshCw
  },
  props: {
    _attrsWithoutClick: {
      type: Object,
      default: () => ({}),
    },
    content: {
      type: Object,
      default: () => ({}),
    },
    uid: { type: String, required: true },
    /* wwEditor:start */
    wwEditorState: { type: Object, default: () => ({}) },
    /* wwEditor:end */
  },
  emits: ['trigger-event', 'update:content'],
  setup(props, { emit }) {
    // ============================================================================
    // DEBUG LOGGER
    // ============================================================================
    // Configurable logger controlled by debugMode prop from WeWeb
    // Can be toggled via WeWeb UI without code changes
    const DEBUG_MODE = computed(() => props.content?.debugMode ?? false);

    // Store original console references to avoid recursion
    const originalConsole = {
      log: console.log.bind(console),
      warn: console.warn.bind(console),
      error: console.error.bind(console),
      info: console.info.bind(console)
    };

    const logger = {
      log: (...args) => {
        if (DEBUG_MODE.value) originalConsole.log(...args);
      },
      warn: (...args) => {
        if (DEBUG_MODE.value) originalConsole.warn(...args);
      },
      error: (...args) => {
        // Errors are always logged, even in production
        originalConsole.error(...args);
      },
      info: (...args) => {
        if (DEBUG_MODE.value) originalConsole.info(...args);
      }
    };

    // ============================================================================
    // UTILITY: COMPONENT VISIBILITY CHECK (Instance Isolation)
    // ============================================================================
    /**
     * Centralized function to check if THIS component instance is active and should handle events.
     *
     * CRITICAL for preventing multiple instances from interfering with each other.
     * WeWeb loads custom elements globally - this ensures only the VISIBLE instance responds.
     *
     * Checks:
     * 1. Component is mounted (vueFlowRef exists)
     * 2. Component is in the DOM (not detached)
     * 3. Component is visible in viewport (width/height > 0)
     *
     * Usage: Call this at the start of ALL global event handlers, watchers, and side effects.
     *
     * @returns {boolean} True if this instance should handle events, false otherwise
     */
    const isComponentActive = () => {
      // Check 1: Component must be mounted
      const container = vueFlowRef.value?.$el || vueFlowRef.value;
      if (!container) {
        logger.log('⏭️ Component not active - not mounted (UID:', props.uid, ')');
        return false;
      }

      // Check 2: Component must be in the DOM
      const doc = wwLib.getFrontDocument() || document;
      if (!doc.body.contains(container)) {
        logger.log('⏭️ Component not active - not in DOM (UID:', props.uid, ')');
        return false;
      }

      // Check 3: Component must be visible (not display:none or off-screen)
      const rect = container.getBoundingClientRect();
      const isVisible = rect.width > 0 && rect.height > 0;

      if (!isVisible) {
        logger.log('⏭️ Component not active - not visible (UID:', props.uid, ')');
        return false;
      }

      logger.log('✅ Component is active (UID:', props.uid, ')');
      return true;
    };

    // ============================================================================
    // CONSTANTS
    // ============================================================================
    const NodeTypes = {
      START: 'start',
      TEXT: 'text',
      CARD: 'card',
      TRAFFIC: 'traffic',
      WAIT: 'wait',
      ERROR: 'error' // Fallback for unknown/deprecated node types
    };

    const EventNames = {
      FLOW_SAVED: 'flowSaved',
      FLOW_EXPORTED: 'flowExported',
      FLOW_IMPORTED: 'flowImported',
      FLOW_CHANGED: 'flowChanged',
      NODE_ADDED: 'nodeAdded',
      NODE_DELETED: 'nodeDeleted',
      NODE_EDITED: 'nodeEdited'
    };

    const ToastTypes = {
      SUCCESS: 'success',
      ERROR: 'error',
      WARNING: 'warning',
      INFO: 'info'
    };

    const Colors = {
      PRIMARY: '#3b82f6',      // Blue - primary color
      SUCCESS: '#10b981',      // Green - success, snap highlight
      WARNING: '#f59e0b',      // Amber - warnings, hover
      ERROR: '#ef4444',        // Red - errors, destructive
      PURPLE: '#8b5cf6',       // Purple - accent
      NEUTRAL: '#b1b1b7',      // Gray - default stroke
    };

    const Distances = {
      HELPER_LINE_THRESHOLD: 5,   // pixels threshold for node alignment snapping
      MIN_CONNECTION_DISTANCE: 75, // minimum distance to show connection hint
      SNAP_DISTANCE: 30,           // distance to snap to handle
    };

    // Centralized UI dimensions (Task 12)
    const UI_SIZES = {
      HANDLE_SMALL: 12,           // Small handle size (12px)
      HANDLE_MEDIUM: 20,          // Medium handle size (20px)
      ICON_SMALL: 14,             // Small icon size (14px)
      ICON_MEDIUM: 16,            // Medium icon size (16px)
      ICON_LARGE: 20,             // Large icon size (20px)
      ICON_XLARGE: 32,            // Extra large icon size (32px)
      SIDEBAR_WIDTH: 260,         // Edit sidebar width (260px)
      DOCK_LEFT_POSITION: 16,     // Dock left offset (16px)
      NODE_DEFAULT_WIDTH: 260,    // Default node width (260px)
      NODE_DEFAULT_HEIGHT: 100,   // Default node height (100px)
    };

    // Helper lines configuration (Task 12)
    const HELPER_LINES = {
      COLOR: '#00AF79',           // Green alignment line color
      WIDTH: 2,                   // Line stroke width
      DASH_PATTERN: [5, 5],       // Dash pattern [dash, gap]
    };

    // Z-index layers (Task 12)
    const Z_INDEX = {
      HELPER_LINES: 9999,         // Helper lines canvas
      EDIT_SIDEBAR: 1001,         // Edit sidebar
      DOCK: 1000,                 // Components dock
      TOOLBAR: 1000,              // Toolbar
      TOAST: 10000,               // Toast notifications (highest)
    };

    // Node manipulation constants
    const DUPLICATE_OFFSET = 50;  // Offset for duplicated nodes (px)

    // ============================================================================
    // COMPOSABLE: TOAST NOTIFICATIONS
    // ============================================================================
    function useToasts() {
      const toasts = ref([]);
      let toastIdCounter = 0;
      const recentToasts = new Map(); // Track recent toasts to prevent spam

      const showToast = (title, message = '', type = ToastTypes.INFO, duration = 3000) => {
        // Throttle: prevent same toast from appearing within 2 seconds
        const toastKey = `${title}:${type}`;
        const now = Date.now();
        const lastShown = recentToasts.get(toastKey);

        if (lastShown && (now - lastShown) < 2000) {
          logger.log('⏭️ Toast throttled (too soon):', title, `Last shown: ${now - lastShown}ms ago`);
          return null; // Don't show duplicate toast
        }

        recentToasts.set(toastKey, now);

        const id = ++toastIdCounter;
        const toast = { id, title, message, type };
        toasts.value.push(toast);

        // Debug: Log toast creation with stack trace
        if (DEBUG_MODE.value) {
          logger.log('🍞 Toast created:', { id, title, message, type });
          logger.log('📍 Call stack:', new Error().stack);
        }

        if (duration > 0) {
          safeSetTimeout(() => {
            removeToast(id);
          }, duration);
        }

        return id;
      };

      const removeToast = (id) => {
        const index = toasts.value.findIndex(t => t.id === id);
        if (index !== -1) {
          toasts.value.splice(index, 1);
        }
      };

      return { toasts, showToast, removeToast };
    }

    // ============================================================================
    // COMPOSABLE: DIALOG SYSTEM
    // ============================================================================
    function useDialog() {
      const dialogState = reactive({
        isVisible: false,
        type: 'confirm', // 'confirm' or 'alert'
        title: '',
        message: '',
        resolve: null
      });

      const showDialog = (message, title, type = 'confirm') => {
        return new Promise((resolve) => {
          dialogState.message = message;
          dialogState.title = title;
          dialogState.type = type;
          dialogState.isVisible = true;
          dialogState.resolve = resolve;
        });
      };

      const showAlert = (message, title = 'Atenção') => {
        return showDialog(message, title, 'alert');
      };

      const showConfirm = (message, title = 'Confirmar') => {
        return showDialog(message, title, 'confirm');
      };

      const closeDialog = (result = false) => {
        if (dialogState.resolve) {
          dialogState.resolve(result);
        }
        dialogState.isVisible = false;
        dialogState.message = '';
        dialogState.title = '';
        dialogState.resolve = null;
      };

      return { dialogState, showAlert, showConfirm, closeDialog };
    }

    // ============================================================================
    // COMPOSABLE: TOOLTIP SYSTEM
    // ============================================================================
    function useTooltip() {
      const tooltipState = reactive({
        visible: false,
        nodeId: null,
        x: 0,
        y: 0
      });

      const showTooltip = (nodeId, event) => {
        const rect = event.target.getBoundingClientRect();
        tooltipState.visible = true;
        tooltipState.nodeId = nodeId;
        tooltipState.x = rect.left + rect.width / 2;
        tooltipState.y = rect.top - 8;
      };

      const hideTooltip = () => {
        tooltipState.visible = false;
        tooltipState.nodeId = null;
      };

      return { tooltipState, showTooltip, hideTooltip };
    }

    // Vue Flow composable
    const {
      fitView,
      project,
      vueFlowRef,
      viewport,
      dimensions,
      getNodes,
      connectionStartHandle,
      getViewport,
      setViewport,
      // Official functions for state management
      addNodes,
      removeNodes,
      addEdges,
      removeEdges
    } = useVueFlow();

    // Reactive state
    const nodes = ref([]);
    const edges = ref([]);
    const isLoadingInitial = ref(false);
    const hoveredEdge = ref(null);
    const isSpacePressed = ref(false);

    // Default edge options
    const defaultEdgeOptions = {
      type: 'smoothstep',
      animated: false,
      markerEnd: {
        type: MarkerType.ArrowClosed
      }
    };

    // Edit sidebar state
    const editingSidebar = reactive({
      visible: false,
      node: null,
      data: {}
    });

    // Dock collapse state
    const isDockCollapsed = ref(false);

    // ===== HIGH-ROI IMPROVEMENTS: Timeout & Upload Management =====
    // Timeout tracking for proper cleanup
    const timeouts = new Set();
    const intervals = new Set();

    const safeSetTimeout = (fn, delay) => {
      const id = setTimeout(() => {
        timeouts.delete(id);
        fn();
      }, delay);
      timeouts.add(id);
      return id;
    };

    const safeSetInterval = (fn, delay) => {
      const id = setInterval(fn, delay);
      intervals.add(id);
      return id;
    };

    const clearAllTimeouts = () => {
      timeouts.forEach(clearTimeout);
      timeouts.clear();
      intervals.forEach(clearInterval);
      intervals.clear();
    };

    // Upload abort controller for canceling in-flight requests
    let uploadAbortController = null;

    // Child node menu state (contextual menu for + button)
    const childNodeMenu = reactive({
      visible: false,
      parentId: null,
      x: 0,
      y: 0
    });

    // Node actions menu state (3-dots menu)
    const actionsMenu = reactive({
      visible: false,
      nodeId: null,
      x: 0,
      y: 0
    });

    // Drag and drop state
    const draggedType = ref(null);
    const isDragging = ref(false);

    // Race condition protection flags
    const isProcessingSave = ref(false);
    const isProcessingUpload = ref(false);
    const isProcessingClear = ref(false);

    // Nielsen #5: Error Prevention - Track unsaved changes
    const hasUnsavedChanges = ref(false);
    const lastSavedState = ref(null);

    // ============================================================================
    // INITIALIZE COMPOSABLES
    // ============================================================================
    const { toasts, showToast, removeToast } = useToasts();
    const { dialogState, showAlert, showConfirm, closeDialog } = useDialog();
    const { tooltipState, showTooltip, hideTooltip } = useTooltip();

    // Helper Lines state for alignment
    const helperLines = reactive({
      horizontal: undefined,
      vertical: undefined
    });

    // Connection preview state (Phase 3: Visual feedback during drag)
    const connectionPreview = reactive({
      active: false,
      sourceNode: null,
      sourceHandle: null
    });



    // Helper Lines canvas ref and drawing function
    const helperLinesCanvasRef = ref(null);

    const drawHelperLines = () => {
      const canvas = helperLinesCanvasRef.value;
      if (!canvas) return;

      const ctx = canvas.getContext('2d');
      if (!ctx) return;

      const win = wwLib.getFrontWindow() || (typeof window !== 'undefined' ? window : null);
      const dpi = win?.devicePixelRatio || 1;
      const width = dimensions.value.width;
      const height = dimensions.value.height;

      canvas.width = width * dpi;
      canvas.height = height * dpi;

      ctx.scale(dpi, dpi);
      ctx.clearRect(0, 0, width, height);

      const { x, y, zoom } = viewport.value;

      ctx.strokeStyle = HELPER_LINES.COLOR;
      ctx.lineWidth = HELPER_LINES.WIDTH;
      ctx.setLineDash(HELPER_LINES.DASH_PATTERN);

      // Draw horizontal line
      if (typeof helperLines.horizontal === 'number') {
        const yPos = helperLines.horizontal * zoom + y;
        ctx.beginPath();
        ctx.moveTo(0, yPos);
        ctx.lineTo(width, yPos);
        ctx.stroke();
      }

      // Draw vertical line
      if (typeof helperLines.vertical === 'number') {
        const xPos = helperLines.vertical * zoom + x;
        ctx.beginPath();
        ctx.moveTo(xPos, 0);
        ctx.lineTo(xPos, height);
        ctx.stroke();
      }
    };

    // Watch for changes to redraw helper lines
    watch([() => helperLines.horizontal, () => helperLines.vertical, () => viewport.value, () => dimensions.value], drawHelperLines, { deep: true });

    // Helper Lines functions for node alignment
    const getHelperLines = (change, nodeId) => {
      const nodeA = nodes.value.find((node) => node.id === nodeId);
      if (!nodeA) return { horizontal: undefined, vertical: undefined };

      const nodeBounds = {
        left: change.position.x,
        right: change.position.x + (nodeA.dimensions?.width || UI_SIZES.NODE_DEFAULT_WIDTH),
        top: change.position.y,
        bottom: change.position.y + (nodeA.dimensions?.height || UI_SIZES.NODE_DEFAULT_HEIGHT),
        centerX: change.position.x + ((nodeA.dimensions?.width || UI_SIZES.NODE_DEFAULT_WIDTH) / 2),
        centerY: change.position.y + ((nodeA.dimensions?.height || UI_SIZES.NODE_DEFAULT_HEIGHT) / 2),
      };

      let horizontalLine = undefined;
      let verticalLine = undefined;
      let minHorizontalDistance = Distances.HELPER_LINE_THRESHOLD;
      let minVerticalDistance = Distances.HELPER_LINE_THRESHOLD;

      // Compare with all other nodes
      nodes.value.forEach((nodeB) => {
        if (nodeB.id === nodeId) return;

        const nodeBBounds = {
          left: nodeB.position.x,
          right: nodeB.position.x + (nodeB.dimensions?.width || UI_SIZES.NODE_DEFAULT_WIDTH),
          top: nodeB.position.y,
          bottom: nodeB.position.y + (nodeB.dimensions?.height || UI_SIZES.NODE_DEFAULT_HEIGHT),
          centerX: nodeB.position.x + ((nodeB.dimensions?.width || UI_SIZES.NODE_DEFAULT_WIDTH) / 2),
          centerY: nodeB.position.y + ((nodeB.dimensions?.height || UI_SIZES.NODE_DEFAULT_HEIGHT) / 2),
        };

        // Check vertical alignment (left, center, right)
        const verticalChecks = [
          { line: nodeBBounds.left, point: nodeBounds.left },
          { line: nodeBBounds.centerX, point: nodeBounds.centerX },
          { line: nodeBBounds.right, point: nodeBounds.right },
        ];

        verticalChecks.forEach(({ line, point }) => {
          const distance = Math.abs(line - point);
          if (distance < minVerticalDistance) {
            minVerticalDistance = distance;
            verticalLine = line;
          }
        });

        // Check horizontal alignment (top, center, bottom)
        const horizontalChecks = [
          { line: nodeBBounds.top, point: nodeBounds.top },
          { line: nodeBBounds.centerY, point: nodeBounds.centerY },
          { line: nodeBBounds.bottom, point: nodeBounds.bottom },
        ];

        horizontalChecks.forEach(({ line, point }) => {
          const distance = Math.abs(line - point);
          if (distance < minHorizontalDistance) {
            minHorizontalDistance = distance;
            horizontalLine = line;
          }
        });
      });

      return { horizontal: horizontalLine, vertical: verticalLine };
    };

    // Throttle helper lines update to 60fps using requestAnimationFrame
    let rafId = null;
    let lastDragEvent = null;

    const updateHelperLines = () => {
      if (!lastDragEvent) return;

      const lines = getHelperLines(
        { position: lastDragEvent.node.position },
        lastDragEvent.node.id
      );

      helperLines.horizontal = lines.horizontal;
      helperLines.vertical = lines.vertical;

      rafId = null;
      lastDragEvent = null;
    };

    const onNodeDrag = (event) => {
      if (!event.node) return;

      lastDragEvent = event;

      // Throttle: Only schedule update if not already scheduled
      if (rafId === null) {
        rafId = requestAnimationFrame(updateHelperLines);
      }
    };

    const onNodeDragStop = () => {
      // Cancel pending animation frame
      if (rafId !== null) {
        cancelAnimationFrame(rafId);
        rafId = null;
      }

      helperLines.horizontal = undefined;
      helperLines.vertical = undefined;
      lastDragEvent = null;
    };

    // Connection radius - get Bezier path helper
    const getConnectionPath = (sourceX, sourceY, targetX, targetY, sourcePosition, targetPosition) => {
      const [path] = getBezierPath({
        sourceX,
        sourceY,
        targetX,
        targetY,
        sourcePosition,
        targetPosition
      });
      return path;
    };

    // Connection radius - get stroke color based on proximity
    const getConnectionStrokeColor = (targetX, targetY) => {
      if (!connectionStartHandle.value) {
        return props.content?.accentColor || Colors.PRIMARY;
      }

      const closestNode = getNodes.value.reduce(
        (res, n) => {
          if (n.id !== connectionStartHandle.value?.nodeId) {
            const dx = targetX - (n.computedPosition.x + (n.dimensions?.width || UI_SIZES.NODE_DEFAULT_WIDTH) / 2);
            const dy = targetY - (n.computedPosition.y + (n.dimensions?.height || UI_SIZES.NODE_DEFAULT_HEIGHT) / 2);
            const d = Math.sqrt(dx * dx + dy * dy);

            if (d < res.distance && d < Distances.MIN_CONNECTION_DISTANCE) {
              res.distance = d;
              res.node = n;
            }
          }

          return res;
        },
        {
          distance: Number.MAX_VALUE,
          node: null
        }
      );

      if (!closestNode.node) {
        return props.content?.accentColor || Colors.PRIMARY;
      }

      const canSnap = closestNode.distance < Distances.SNAP_DISTANCE;

      // Return color based on proximity
      if (canSnap) {
        return Colors.SUCCESS; // Green - can snap
      } else {
        return Colors.WARNING; // Amber - nearby
      }
    };

    // Undo/Redo state
    const history = ref([]);
    const historyIndex = ref(-1);
    const maxHistorySize = 50;

    // ============================================================================
    // HELPER FUNCTIONS: START NODE UTILITIES (DRY - Don't Repeat Yourself)
    // ============================================================================
    const getStartNodes = () => nodes.value.filter(n => n.type === NodeTypes.START);
    const hasMultipleStartNodes = () => getStartNodes().length > 1;
    const getStartNode = () => getStartNodes()[0] || null;
    const isStartNode = (nodeId) => {
      const node = nodes.value.find(n => n.id === nodeId);
      return node?.type === NodeTypes.START;
    };

    // Available components for dock (Start is auto-created, not in dock)
    const availableComponents = computed(() => [
      { type: NodeTypes.TEXT, title: 'Texto', icon: MessageSquare, description: 'Mensagem de texto simples' },
      { type: NodeTypes.CARD, title: 'Imagem', icon: ImageIcon, description: 'Card com imagem e botões' },
      { type: NodeTypes.TRAFFIC, title: 'Tráfego', icon: GitBranch, description: 'Divisor de tráfego com % de distribuição' },
      { type: NodeTypes.WAIT, title: 'Aguardar', icon: Clock, description: 'Temporizador de espera' }
    ]);

    // Get the node currently shown in actions menu
    const actionsMenuNode = computed(() => {
      if (!actionsMenu.nodeId) return null;
      return nodes.value.find(n => n.id === actionsMenu.nodeId);
    });

    // Debounce utility function
    const debounce = (func, wait) => {
      let timeout;
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout);
          func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
      };
    };

    // Handle nodes change
    const onNodesChange = (changes) => {
      // Use Vue Flow's official helper to apply changes
      // This maintains the internal state of the library correctly
      nodes.value = applyNodeChanges(changes, nodes.value);

      // Only emit if there were actual position changes (with debounce to avoid excessive emissions)
      if (changes.some(c => c.type === 'position')) {
        debouncedEmitFlowChanged();
      }
    };

    // Handle edges change
    const onEdgesChange = (changes) => {
      // Use Vue Flow's official helper to apply changes
      // This maintains the internal state of the library correctly
      edges.value = applyEdgeChanges(changes, edges.value);

      // Log selection changes for debugging
      changes.forEach(change => {
        if (change.type === 'select') {
          logger.log(`🔵 Edge ${change.id} selected:`, change.selected);
        }
      });

      // Emit flow changed when edges are removed
      if (changes.some(c => c.type === 'remove')) {
        emitFlowChanged();
      }
    };

    // Handle pane click - deselect all when clicking on canvas without Shift
    const onPaneClick = (event) => {
      // Only deselect if Shift is NOT pressed
      if (!event.shiftKey) {
        logger.log('🔵 Pane clicked without Shift - deselecting all');
        // Map transformation (property modification) - acceptable pattern
        nodes.value = nodes.value.map(n => ({ ...n, selected: false }));
        edges.value = edges.value.map(e => ({ ...e, selected: false }));
      } else {
        logger.log('🔵 Pane clicked with Shift - keeping selection');
      }
    };

    // ============================================================================
    // CONNECTION VALIDATION HELPERS (Task 11 - Refactored from onConnect)
    // ============================================================================

    /**
     * Validates if a connection is allowed based on node types and existing connections.
     * This is called by VueFlow BEFORE allowing the user to create a connection.
     *
     * Connection Rules:
     * - Start node: 0 inputs, max 1 output
     * - Text/Card/Wait nodes: max 1 input, max 1 output
     * - Traffic node: max 1 input, unlimited outputs (one per branch via sourceHandle)
     * - No self-connections
     * - No connections TO start node
     * - No cycles (infinite loops)
     */
    /**
     * SILENT validation for connection preview (called many times during drag).
     * Returns only true/false WITHOUT showing toasts.
     * This prevents toast spam during connection dragging.
     */
    const isValidConnection = (connection) => {
      const sourceNode = nodes.value.find(n => n.id === connection.source);
      const targetNode = nodes.value.find(n => n.id === connection.target);

      if (!sourceNode || !targetNode) {
        return false;
      }

      // Rule 1: No self-connections (silent check)
      if (connection.source === connection.target) {
        return false;
      }

      // Rule 2: Start node cannot receive connections (silent check)
      if (targetNode.type === NodeTypes.START) {
        return false;
      }

      // Rule 3: Check for cycles (silent check)
      const wouldCreateCycle = (sourceId, targetId) => {
        const visited = new Set();
        const checkPath = (currentId) => {
          if (currentId === sourceId) return true;
          if (visited.has(currentId)) return false;

          visited.add(currentId);

          const outgoingEdges = edges.value.filter(e => e.source === currentId);
          return outgoingEdges.some(e => checkPath(e.target));
        };

        return checkPath(targetId);
      };

      if (wouldCreateCycle(connection.source, connection.target)) {
        return false;
      }

      return true; // Connection is valid
    };

    /**
     * VERBOSE validation with user feedback (toasts).
     * Called ONCE when connection is dropped (not during drag).
     * Returns { valid: boolean, reason: string }
     */
    const validateConnectionWithFeedback = (connection) => {
      const sourceNode = nodes.value.find(n => n.id === connection.source);
      const targetNode = nodes.value.find(n => n.id === connection.target);

      if (!sourceNode || !targetNode) {
        return { valid: false, reason: 'Nós não encontrados' };
      }

      // Rule 1: No self-connections
      if (connection.source === connection.target) {
        showToast(
          'Conexão Inválida',
          'Um nó não pode se conectar a si mesmo.\n\n💡 Sugestão: Conecte a um nó diferente ou crie um novo nó.',
          ToastTypes.WARNING,
          3500
        );
        return { valid: false, reason: 'self-connection' };
      }

      // Rule 2: Start node cannot receive connections
      if (targetNode.type === NodeTypes.START) {
        showToast(
          'Conexão Bloqueada',
          'O nó START não pode receber conexões de entrada.\n\n💡 Sugestão: O fluxo sempre começa no START. Conecte a partir do START para outros nós.',
          ToastTypes.WARNING,
          4000
        );
        return { valid: false, reason: 'start-node-input' };
      }

      // Rule 3: Check for cycles (would create infinite loop)
      // Algorithm: If there's already a path from TARGET to SOURCE,
      // then adding SOURCE -> TARGET would create a cycle
      const wouldCreateCycle = (sourceId, targetId) => {
        const visited = new Set();
        const checkPath = (currentId) => {
          // Found path back to source = CYCLE!
          if (currentId === sourceId) return true;

          // Already visited = not a cycle through this path
          if (visited.has(currentId)) return false;

          visited.add(currentId);

          // Check all outgoing connections from current node
          const outgoingEdges = edges.value.filter(e => e.source === currentId);
          return outgoingEdges.some(e => checkPath(e.target));
        };

        return checkPath(targetId);
      };

      if (wouldCreateCycle(connection.source, connection.target)) {
        showToast(
          '🔴 Loop Infinito Detectado',
          'Esta conexão criaria um caminho circular no fluxo, causando um loop infinito.\n\n💡 Sugestão: Conecte a um nó diferente que não crie um ciclo de volta.',
          ToastTypes.WARNING,
          4500
        );
        return { valid: false, reason: 'cycle-detected' };
      }

      return { valid: true, reason: '' };
    };


    /**
     * Handle new connection creation with AUTO-REPLACEMENT.
     *
     * UX Improvement (Nielsen #7 - Flexibility and Efficiency):
     * - Auto-deletes old connections when creating new ones (1 action instead of 2)
     * - Provides clear feedback about what was replaced
     * - Supports Undo (saveHistory before changes)
     *
     * Behavior:
     * 1. If target already has input → Replace it
     * 2. If source (non-traffic) already has output → Replace it
     * 3. Create new connection
     * 4. Show toast with replacement info
     */
    const onConnect = async (params) => {
      logger.log('🔗 Creating connection:', params);

      // Validate connection with user feedback (toasts)
      const validation = validateConnectionWithFeedback(params);
      if (!validation.valid) {
        logger.log('❌ Connection blocked:', validation.reason);
        return; // Toast already shown by validateConnectionWithFeedback
      }

      // Save history BEFORE any changes (enables Undo)
      saveHistory();

      // 1. Check if target already has a connection (will be replaced)
      const existingTargetEdge = edges.value.find(e =>
        e.target === params.target &&
        (e.targetHandle || null) === (params.targetHandle || null)
      );

      // 2. Check if source (non-traffic) already has a connection (will be replaced)
      const sourceNode = nodes.value.find(n => n.id === params.source);
      const existingSourceEdge = sourceNode?.type !== NodeTypes.TRAFFIC
        ? edges.value.find(e =>
            e.source === params.source &&
            (e.sourceHandle || null) === (params.sourceHandle || null)
          )
        : null;

      // 3. For traffic nodes, check if specific branch already has connection
      const existingBranchEdge = sourceNode?.type === NodeTypes.TRAFFIC && params.sourceHandle
        ? edges.value.find(e =>
            e.source === params.source &&
            e.sourceHandle === params.sourceHandle
          )
        : null;

      // 4. Collect all edges to remove (auto-replacement)
      const edgesToRemove = [existingTargetEdge, existingSourceEdge, existingBranchEdge].filter(Boolean);

      // 5. Remove old connections if any exist
      if (edgesToRemove.length > 0) {
        logger.log('🔄 Auto-replacing', edgesToRemove.length, 'old connection(s)');
        removeEdges(edgesToRemove);
      }

      // 6. Create the new connection
      const newEdge = {
        id: `edge-${uuidv4()}`,
        source: params.source,
        target: params.target,
        sourceHandle: params.sourceHandle || null,
        targetHandle: params.targetHandle || null,
        ...defaultEdgeOptions
      };

      addEdges([newEdge]);
      emitFlowChanged();

      // 7. Show appropriate feedback
      if (edgesToRemove.length > 0) {
        showToast(
          'Conexão Substituída',
          `${edgesToRemove.length} conexão(ões) substituída(s) • Ctrl+Z para desfazer`,
          ToastTypes.INFO,
          2500
        );
        logger.log('✅ Conexão substituída com sucesso');
      } else {
        showToast('Conectado', 'Conexão criada com sucesso', ToastTypes.SUCCESS, 1500);
        logger.log('✅ Conexão criada com sucesso');
      }
    };

    /**
     * Phase 3: Connection Preview - Visual Feedback During Drag
     *
     * Shows colored connection line based on what will happen:
     * - GREEN (#22c55e): New connection (valid, no replacement)
     * - YELLOW (#eab308): Will replace existing connection
     * - RED (#ef4444): Invalid connection (cycle, START input, etc.)
     */
    const onConnectStart = (event) => {
      connectionPreview.active = true;
      connectionPreview.sourceNode = event.nodeId;
      connectionPreview.sourceHandle = event.handleId;
      logger.log('🎨 Connection preview started:', event);
    };

    const onConnectEnd = () => {
      connectionPreview.active = false;
      connectionPreview.sourceNode = null;
      connectionPreview.sourceHandle = null;
      logger.log('🎨 Connection preview ended');
    };

    /**
     * Computed connection line style - dynamically changes color based on preview state.
     *
     * This is called constantly during drag, so we check:
     * 1. Is connection active?
     * 2. Where is the cursor pointing? (requires VueFlow internals)
     * 3. Would this connection be valid, replace, or invalid?
     */
    const connectionLineStyle = computed(() => {
      if (!connectionPreview.active) {
        // Default style when not dragging
        return { stroke: '#b1b1b7', strokeWidth: 2, fill: 'none' };
      }

      // During drag - check if we're hovering over a valid target
      // VueFlow provides connectionStartHandle which contains source info
      const startHandle = connectionStartHandle.value;

      if (!startHandle) {
        return { stroke: '#b1b1b7', strokeWidth: 2, fill: 'none' };
      }

      // We need to check if there would be a replacement
      // This is a simplified version - full implementation would require
      // tracking mouse position and finding the closest node/handle

      // For now, show yellow (replacement warning) by default during drag
      // to indicate the auto-replacement feature is active
      return {
        stroke: '#eab308', // Yellow - indicates auto-replacement is possible
        strokeWidth: 2.5,
        strokeDasharray: '5,5', // Dashed line during preview
        fill: 'none'
      };
    });

    // Helper function to ensure all items in arrays have UUIDs
    // This prevents v-for key issues when loading data from database or imports
    const ensureArrayItemsHaveIds = (nodeData) => {
      // Ensure buttons have IDs
      if (nodeData.buttons && Array.isArray(nodeData.buttons)) {
        nodeData.buttons = nodeData.buttons.map(button => ({
          ...button,
          id: button.id || uuidv4() // Add ID if missing
        }));
      }

      // Ensure branches have IDs
      if (nodeData.branches && Array.isArray(nodeData.branches)) {
        nodeData.branches = nodeData.branches.map(branch => ({
          ...branch,
          id: branch.id || uuidv4() // Add ID if missing
        }));
      }

      return nodeData;
    };

    // Function to load flow data
    const loadFlowData = (flowData, skipEmit = false) => {
      // CRITICAL: Prevent race condition - Don't load if user is currently editing
      // This prevents data loss when database updates while user has sidebar open
      if (editingSidebar.visible) {
        logger.warn('⚠️ Ignorando carregamento de fluxo: usuário está editando um nó');
        logger.warn('   Para evitar perda de dados, o carregamento será bloqueado até que a edição seja concluída.');
        return;
      }

      if (flowData && typeof flowData === 'object') {
        logger.log('📥 Loading flow data...', flowData);

        // Set loading flag to prevent emit during load
        if (skipEmit) isLoadingInitial.value = true;

        if (flowData.nodes && Array.isArray(flowData.nodes)) {
          // Define valid node types (used for validation)
          const VALID_NODE_TYPES = [NodeTypes.START, NodeTypes.TEXT, NodeTypes.CARD, NodeTypes.TRAFFIC, NodeTypes.WAIT];

          let loadedNodes = flowData.nodes.map(node => {
              // CRITICAL: Validate node.data to prevent "Cannot convert undefined or null to object"
              if (!node.data || typeof node.data !== 'object') {
                logger.warn(`⚠️ Nó com ID ${node.id} (tipo: ${node.type}) possui 'data' inválido:`, node.data);
                logger.warn('   Usando objeto vazio como fallback para prevenir erro.');
              }

              // Check if node type is valid
              const isValidType = VALID_NODE_TYPES.includes(node.type);

              if (!isValidType) {
                logger.warn(`⚠️ Tipo de nó inválido encontrado: "${node.type}" (ID: ${node.id}). Convertendo para nó de erro.`);
              }

              return {
                // Ensure all nodes have UUID: use existing if valid, generate new if missing
                id: node.id && typeof node.id === 'string' && node.id.trim() !== '' ? node.id : uuidv4(),
                // Convert invalid types to error node type
                type: isValidType ? node.type : NodeTypes.ERROR,
                position: { x: node.x, y: node.y },
                // SAFETY: Use fallback empty object if node.data is null/undefined
                // For error nodes, preserve original type in data
                data: isValidType
                  ? ensureArrayItemsHaveIds({ ...(node.data || {}) })
                  : { originalType: node.type, ...ensureArrayItemsHaveIds({ ...(node.data || {}) }) }
              };
            });

          // Validation 1: Remove duplicate start nodes (keep only first)
          const startNodes = loadedNodes.filter(n => n.type === NodeTypes.START);
          if (startNodes.length > 1) {
            logger.warn(`⚠️ Found ${startNodes.length} start nodes. Removing duplicates...`);
            const firstStart = startNodes[0];
            loadedNodes = loadedNodes.filter(n => n.type !== NodeTypes.START || n.id === firstStart.id);
          }

          // Validation 2: Ensure there's always a start node
          if (startNodes.length === 0) {
            logger.warn('⚠️ No start node found. Creating one automatically...');
            const startNode = {
              id: uuidv4(),
              type: NodeTypes.START,
              position: { x: 200, y: 200 },
              data: getDefaultNodeData(NodeTypes.START),
              selectable: true,
              draggable: true
            };
            loadedNodes.unshift(startNode); // Add at the beginning
          }

          // Use official VueFlow API instead of direct assignment
          const allNodes = [...nodes.value];
          if (allNodes.length > 0) removeNodes(allNodes);
          addNodes(loadedNodes);
        }

        if (flowData.connections && Array.isArray(flowData.connections)) {
          // Get all valid node IDs for connection validation
          const validNodeIds = new Set(nodes.value.map(n => n.id));

          // SAFETY: Filter out null/undefined connections before processing
          const validConnections = flowData.connections.filter(conn => {
            if (!conn || typeof conn !== 'object') {
              logger.warn('⚠️ Conexão inválida encontrada (null/undefined). Ignorando...');
              return false;
            }
            if (!conn.from || !conn.to) {
              logger.warn(`⚠️ Conexão malformada (from: ${conn.from}, to: ${conn.to}). Ignorando...`);
              return false;
            }
            // VALIDATION: Filter out orphan connections (nodes that don't exist)
            if (!validNodeIds.has(conn.from) || !validNodeIds.has(conn.to)) {
              logger.warn(`⚠️ Conexão órfã removida (from: ${conn.from}, to: ${conn.to}). Nó não existe mais.`);
              return false;
            }
            return true;
          });

          const loadedEdges = validConnections.map((conn) => ({
            id: `edge-${uuidv4()}`,
            source: conn.from,
            target: conn.to,
            sourceHandle: conn.sourceHandle || undefined,
            targetHandle: conn.targetHandle || undefined,
            ...defaultEdgeOptions
          }));

          // Use official VueFlow API instead of direct assignment
          const allEdges = [...edges.value];
          if (allEdges.length > 0) removeEdges(allEdges);
          addEdges(loadedEdges);
        }

        safeSetTimeout(() => {
          fitView();
          if (skipEmit) isLoadingInitial.value = false;
        }, 100);
      }
    };

    // CRITICAL OPTIMIZATION: Consolidated flow data watchers
    // Previously had 2 separate watchers with JSON.stringify comparison (O(N) blocking operation)
    // Now uses a single watcher with shallow comparison based on metadata
    // This prevents UI freezes when loading large flows (200+ nodes)

    // Track previous flow metadata to avoid expensive deep comparisons
    const previousFlowMetadata = reactive({
      nodesLength: 0,
      edgesLength: 0,
      timestamp: null
    });

    watch(
      () => [props.content?.flowData, props.content?.initialFlow],
      ([newFlowData, newInitialFlow]) => {
        // CRITICAL FIX: Only process flow changes if THIS instance is active
        // This prevents non-visible instances from loading data unnecessarily
        if (!isComponentActive()) {
          logger.log('⏭️ Ignoring flow data change - component not active');
          return;
        }

        // Priority: initialFlow (from database) takes precedence over flowData
        const flowToLoad = newInitialFlow || newFlowData;
        const isFromDatabase = !!newInitialFlow;

        if (flowToLoad && typeof flowToLoad === 'object') {
          // Use metadata comparison instead of JSON.stringify
          // This is O(1) instead of O(N) and doesn't block the UI
          const currentNodesLength = flowToLoad.nodes?.length || 0;
          const currentEdgesLength = flowToLoad.connections?.length || 0;
          const currentTimestamp = flowToLoad.timestamp || flowToLoad.lastModified || Date.now();

          // Check if flow actually changed using metadata
          const hasChanged =
            previousFlowMetadata.nodesLength !== currentNodesLength ||
            previousFlowMetadata.edgesLength !== currentEdgesLength ||
            previousFlowMetadata.timestamp !== currentTimestamp;

          if (hasChanged) {
            // Update metadata
            previousFlowMetadata.nodesLength = currentNodesLength;
            previousFlowMetadata.edgesLength = currentEdgesLength;
            previousFlowMetadata.timestamp = currentTimestamp;

            // Load the flow
            if (isFromDatabase) {
              logger.log('📊 Initial flow updated from database');
              loadFlowData(flowToLoad, true); // Skip emit to prevent loops
            } else {
              loadFlowData(flowToLoad);
            }
          }
        }
      },
      { deep: true }
    );

    // CRITICAL: Store window reference to prevent memory leak
    // If wwLib.getFrontWindow() returns different values between onMounted and onUnmounted,
    // the event listener won't be removed correctly, causing a memory leak.
    let boundWindow = null;

    // Initialize with example flow or initial flow
    onMounted(() => {
      logger.log('🚀 Vue Flow Messenger Builder - Component Mounted');
      logger.log('🆔 COMPONENT UID:', props.uid);
      logger.log('📊 Props:', props);
      logger.log('📋 Content:', props.content);

      // CRITICAL DEBUG: Check how many instances are mounted
      const win = wwLib.getFrontWindow();
      if (win) {
        if (!win.__FLOW_INSTANCES__) {
          win.__FLOW_INSTANCES__ = new Set();
        }
        win.__FLOW_INSTANCES__.add(props.uid);
        logger.log('⚠️ TOTAL INSTANCES MOUNTED:', win.__FLOW_INSTANCES__.size);
        logger.log('⚠️ INSTANCE UIDs:', Array.from(win.__FLOW_INSTANCES__));
      }

      // Check if there's an initial flow to load
      if (props.content?.initialFlow && typeof props.content?.initialFlow === 'object') {
        logger.log('📥 Loading initial flow from props...');
        loadFlowData(props.content?.initialFlow, true); // Skip emit on initial load
      } else if (!nodes.value.length) {
        logger.log('⚡ Loading default flow with start node...');
        loadDefaultFlow();
      }

      // Add keyboard listeners - use WeWeb's window access
      // CRITICAL: Store reference to ensure correct cleanup in onUnmounted
      logger.log('⌨️ Adding keyboard event listeners (Component UID:', props.uid, ')');
      boundWindow = wwLib.getFrontWindow() || (typeof window !== 'undefined' ? window : null);
      if (boundWindow) {
        logger.log('✅ Registering keydown/keyup listeners for component', props.uid);
        boundWindow.addEventListener('keydown', handleKeyDown);
        boundWindow.addEventListener('keyup', handleKeyUp);

        // Nielsen #5: Error Prevention - Warn before leaving page with unsaved changes
        // CRITICAL FIX: Only warn if THIS component instance is visible
        const handleBeforeUnload = (event) => {
          // Check if this component instance is actually visible
          const container = vueFlowRef.value?.$el || vueFlowRef.value;
          if (!container) {
            logger.log('⏭️ Ignoring beforeunload - component not mounted (UID:', props.uid, ')');
            return;
          }

          const rect = container.getBoundingClientRect();
          const isVisible = rect.width > 0 && rect.height > 0 && rect.top < window.innerHeight && rect.bottom > 0;

          if (!isVisible) {
            logger.log('⏭️ Ignoring beforeunload - component not visible (UID:', props.uid, ')');
            return;
          }

          // Only warn if this visible instance has unsaved changes
          if (hasUnsavedChanges.value && props.content?.enableEdit) {
            logger.log('⚠️ beforeunload triggered by visible component (UID:', props.uid, ')');
            event.preventDefault();
            event.returnValue = ''; // Chrome requires returnValue to be set
            return 'Você tem alterações não salvas. Deseja realmente sair?';
          }
        };
        boundWindow.addEventListener('beforeunload', handleBeforeUnload);

        logger.log('✅ Keyboard and beforeunload listeners attached to window:', boundWindow === window ? 'global' : 'WeWeb');
      } else {
        logger.error('❌ No window available for keyboard listeners');
      }

      // ============================================================================
      // EXPOSE COMPONENT INSTANCE FOR AUTOMATED TESTS (Multiple Instance Support)
      // ============================================================================
      // CRITICAL IMPROVEMENT: Use Map to store instances by UID instead of singleton
      // This allows tests to access specific instances without conflicts
      if (props.content?.enableEdit) {
        const win = wwLib.getFrontWindow() || (typeof window !== 'undefined' ? window : null);
        if (win) {
          // Initialize Map if it doesn't exist
          if (!win.__VUE_FLOW_INSTANCES_MAP__) {
            win.__VUE_FLOW_INSTANCES_MAP__ = new Map();
          }

          // Store this instance by UID
          win.__VUE_FLOW_INSTANCES_MAP__.set(props.uid, {
            // Metadata
            uid: props.uid,
            mountedAt: Date.now(),

            // State refs (reactive)
            nodes,
            edges,
            editingSidebar,
            toasts,
            validationState,

            // Constants
            NodeTypes,
            EventNames,
            ToastTypes,

            // VueFlow native methods
            addNodes,
            removeNodes,
            addEdges,
            removeEdges,
            getViewport,
            setViewport,
            fitView,
            project,

            // Component methods
            addNode,
            deleteNode,
            deleteEdge,
            editNode,
            saveNodeEdit,
            closeEditSidebar,
            autoLayout,
            clearFlow,
            saveFlow,
            exportFlow,
            importFlow,
            validateFlow,
            validateNode,
            undo,
            redo,
            saveHistory,
            showToast,

            // Utility
            logger,
            DEBUG_MODE,
            isComponentActive
          });

          // BACKWARD COMPATIBILITY: Keep singleton for latest mounted instance
          // This ensures existing tests continue to work
          win.__VUE_FLOW_INSTANCE__ = win.__VUE_FLOW_INSTANCES_MAP__.get(props.uid);

          logger.log('✅ VueFlow instance exposed to Map (UID:', props.uid, ')');
          logger.log('📊 Total instances in Map:', win.__VUE_FLOW_INSTANCES_MAP__.size);
        }
      }
    });

    onUnmounted(() => {
      logger.log('🔴 Component UNMOUNTING - UID:', props.uid);

      // ============================================================================
      // CRITICAL: COMPLETE CLEANUP TO PREVENT MEMORY LEAKS AND INTERFERENCE
      // ============================================================================

      const win = wwLib.getFrontWindow();

      // 1. Remove from instance tracking Set
      if (win && win.__FLOW_INSTANCES__) {
        win.__FLOW_INSTANCES__.delete(props.uid);
        logger.log('⚠️ REMAINING INSTANCES:', win.__FLOW_INSTANCES__.size);
        logger.log('⚠️ REMAINING UIDs:', Array.from(win.__FLOW_INSTANCES__));
      }

      // 2. Remove from instances Map with ENHANCED deep cleanup (MEMORY LEAK FIX)
      if (win && win.__VUE_FLOW_INSTANCES_MAP__) {
        const instance = win.__VUE_FLOW_INSTANCES_MAP__.get(props.uid);

        // HIGH-ROI: Deep cleanup - clear all object properties to break circular references
        if (instance) {
          Object.keys(instance).forEach(key => {
            try {
              delete instance[key];
            } catch (e) {
              logger.warn('Could not delete property:', key);
            }
          });
        }

        win.__VUE_FLOW_INSTANCES_MAP__.delete(props.uid);
        logger.log('📊 Instances removed from Map. Remaining:', win.__VUE_FLOW_INSTANCES_MAP__.size);

        // If this was the last instance, clean up singleton reference
        if (win.__VUE_FLOW_INSTANCES_MAP__.size === 0) {
          delete win.__VUE_FLOW_INSTANCE__;
          logger.log('🧹 Last instance removed - singleton cleaned up');
        }
      }

      // 3. Remove actions from window namespace
      if (win) {
        const actionsKey = `wwElement_${props.uid}_actions`;
        if (win[actionsKey]) {
          delete win[actionsKey];
          logger.log('🧹 Actions removed from window:', actionsKey);
        }
      }

      // 4. HIGH-ROI: Clear all timeouts and intervals
      clearAllTimeouts();
      logger.log('✅ All timeouts/intervals cleared');

      // 5. HIGH-ROI: Abort ongoing async operations
      uploadAbortController?.abort();
      logger.log('✅ Upload operations aborted');

      // 6. Remove event listeners using the SAME window reference from onMounted
      // CRITICAL: This prevents memory leak by ensuring we remove from the correct window
      if (boundWindow) {
        boundWindow.removeEventListener('keydown', handleKeyDown);
        boundWindow.removeEventListener('keyup', handleKeyUp);
        boundWindow.removeEventListener('beforeunload', handleBeforeUnload);
        logger.log('✅ Event listeners removed successfully');
        boundWindow = null; // Clear reference to prevent memory leak
      }

      logger.log('✅ Component cleanup complete - UID:', props.uid);
    });


    // Node management
    const getDefaultNodeData = (type) => {
      switch(type) {
        case 'start':
          return { label: 'Início do Fluxo' };
        case 'text':
          return {
            label: 'Mensagem de Texto',
            messageType: 'ACCOUNT_UPDATE',
            text: '',
            buttons: []
          };
        case 'card':
          return {
            label: 'Card do Messenger',
            messageType: 'ACCOUNT_UPDATE',
            title: '',
            subtitle: '',
            imageUrl: '',
            imageAspectRatio: 'square',
            url: '',
            buttons: []
          };
        case 'wait':
          return {
            label: 'Aguardar',
            duration: 5,
            timeUnit: 'seconds'
          };
        case 'traffic':
          return {
            label: 'Divisor de Tráfego',
            branches: [
              { id: uuidv4(), percentage: 50, label: 'Opção A' },
              { id: uuidv4(), percentage: 50, label: 'Opção B' }
            ]
          };
        default:
          return { label: 'Nó' };
      }
    };

    const addNode = (type, customPosition = null) => {
      // Validação: apenas 1 node de início permitido
      if (type === NodeTypes.START) {
        const hasStartNode = nodes.value.some(n => n.type === NodeTypes.START);
        if (hasStartNode) {
          logger.warn('⚠️ Já existe um node de início. Apenas 1 permitido.');
          showToast('Aviso', 'Apenas um nó de início é permitido', ToastTypes.WARNING, 2000);
          return;
        }
      }

      saveHistory(); // Save state before adding

      const id = uuidv4();

      // Use custom position if provided, otherwise calculate
      let position;
      if (customPosition) {
        position = customPosition;
      } else if (nodes.value.length > 0) {
        // Find the rightmost node
        const maxX = Math.max(...nodes.value.map(n => n.position.x));
        position = {
          x: maxX + 250,
          y: 100 + Math.random() * 50
        };
      } else {
        position = { x: 100, y: 100 };
      }

      const newNode = {
        id,
        type,
        position,
        data: getDefaultNodeData(type),
        selectable: true,
        draggable: true
      };

      // Use official addNodes function
      addNodes([newNode]);
      logger.log('🆕 Node added:', newNode);
      emitFlowChanged();

      emit('trigger-event', {
        name: 'nodeAdded',
        event: {
          node: newNode,
          nodeType: type,
          position
        }
      });
    };

    // Drag and Drop handlers
    const onDockItemClick = (type) => {
      // Only trigger click if not dragging
      if (!isDragging.value) {
        addNode(type);
      }
      isDragging.value = false;
    };

    const onDragStart = (type, event) => {
      logger.log('🚀 Drag started:', type);
      draggedType.value = type;
      isDragging.value = true;
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('application/vueflow-node-type', type);
    };

    const onDragEnd = () => {
      logger.log('🏁 Drag ended');
      isDragging.value = false;
      draggedType.value = null;
    };

    const onDragOver = (event) => {
      event.preventDefault();
      if (draggedType.value) {
        event.dataTransfer.dropEffect = 'move';
      }
    };

    const onDrop = (event) => {
      event.preventDefault();
      logger.log('📦 Drop event triggered');

      const type = draggedType.value || event.dataTransfer.getData('application/vueflow-node-type');
      logger.log('📌 Type:', type, '| draggedType.value:', draggedType.value);

      if (!type) {
        logger.warn('⚠️ No type found in drop event');
        return;
      }

      logger.log('🔍 vueFlowRef:', vueFlowRef);
      logger.log('🔍 vueFlowRef.value:', vueFlowRef.value);

      if (!vueFlowRef.value) {
        logger.warn('⚠️ VueFlow ref not found');
        return;
      }

      // Get the bounding rect of the VueFlow container
      const rect = vueFlowRef.value.getBoundingClientRect();
      logger.log('📐 Rect:', rect);

      // Calculate position relative to the flow viewport and project to flow coordinates
      const screenPos = {
        x: event.clientX - rect.left,
        y: event.clientY - rect.top
      };
      logger.log('🖱️ Screen position (before project):', screenPos);

      const position = project(screenPos);
      logger.log('🎯 Flow position (after project):', position);

      // Add node at the dropped position
      addNode(type, position);

      // Reset drag state
      draggedType.value = null;
      isDragging.value = false;
    };

    const deleteNode = async (nodeId) => {
      const node = nodes.value.find(n => n.id === nodeId);
      if (!node) return;

      // Prevent deletion of the only START node (using helper function)
      if (isStartNode(nodeId) && !hasMultipleStartNodes()) {
        showToast('Não é possível deletar', 'O fluxo precisa de pelo menos um nó de início', ToastTypes.WARNING, 3000);
        return;
      }

      // Count connected edges to show in confirmation
      const connectedEdges = edges.value.filter(e => e.source === nodeId || e.target === nodeId);
      const hasConnections = connectedEdges.length > 0;

      // Nielsen #5: Error Prevention - Always confirm before deleting
      const nodeTypeLabel = {
        [NodeTypes.START]: 'Início',
        [NodeTypes.TEXT]: 'Texto',
        [NodeTypes.CARD]: 'Imagem',
        [NodeTypes.TRAFFIC]: 'Divisor de Tráfego',
        [NodeTypes.WAIT]: 'Aguardar'
      }[node.type] || 'Nó';

      let confirmMessage = `Tem certeza que deseja deletar o nó "${nodeTypeLabel}"?`;

      if (hasConnections) {
        confirmMessage += `\n\n⚠️ Este nó possui ${connectedEdges.length} conexão(ões) que também serão removidas.`;
      }

      confirmMessage += '\n\nEsta ação pode ser desfeita com Ctrl+Z.';

      const confirmed = await showConfirm(confirmMessage, 'Confirmar Exclusão');

      if (!confirmed) {
        showToast('Cancelado', 'Exclusão cancelada', ToastTypes.INFO, 1500);
        return;
      }

      // Save history before deletion (enables Undo)
      saveHistory();

      // Use official removeNodes - automatically removes connected edges
      removeNodes([node]);
      emitFlowChanged();

      showToast(
        'Excluído',
        `Nó "${nodeTypeLabel}" excluído${hasConnections ? ` (${connectedEdges.length} conexão(ões) removidas)` : ''}`,
        ToastTypes.SUCCESS,
        2500
      );

      emit('trigger-event', {
        name: 'nodeRemoved',
        event: {
          nodeId,
          nodeType: node.type,
          connectionsRemoved: connectedEdges.length
        }
      });
    };

    const deleteEdge = (edgeId) => {
      logger.log('🗑️ Deletando edge:', edgeId);
      const edge = edges.value.find(e => e.id === edgeId);
      if (!edge) return;

      // Use official removeEdges
      removeEdges([edge]);
      hoveredEdge.value = null;
      emitFlowChanged();
    };

    const handleEdgeHover = (edgeId, isHovered) => {
      if (isHovered) {
        logger.log('🖱️ Edge hovered:', edgeId);
        hoveredEdge.value = edgeId;
      } else {
        hoveredEdge.value = null;
      }
    };


    // Show child node selection menu
    const showChildNodeMenu = (parentId, event) => {
      event.preventDefault();
      event.stopPropagation();

      const button = event.currentTarget;
      const rect = button.getBoundingClientRect();

      logger.log('📍 Button position:', {
        right: rect.right,
        top: rect.top,
        left: rect.left,
        bottom: rect.bottom
      });

      childNodeMenu.parentId = parentId;
      childNodeMenu.x = rect.right + 10; // 10px to the right of button
      childNodeMenu.y = rect.top;
      childNodeMenu.visible = true;

      logger.log('📍 Menu will appear at:', { x: childNodeMenu.x, y: childNodeMenu.y });
    };

    // Close child node menu
    const closeChildNodeMenu = () => {
      childNodeMenu.visible = false;
      childNodeMenu.parentId = null;
    };

    // Create child node of specific type
    const createChildNode = (childType) => {
      const parentId = childNodeMenu.parentId;
      if (!parentId) return;

      const parent = nodes.value.find(n => n.id === parentId);
      if (!parent) return;

      const newNode = {
        id: uuidv4(),
        type: childType,
        position: {
          x: parent.position.x,
          y: parent.position.y + 150
        },
        data: getDefaultNodeData(childType),
        selectable: true,
        draggable: true
      };

      // Use official addNodes function
      addNodes([newNode]);

      const newEdge = {
        id: `edge-${uuidv4()}`,
        source: parentId,
        target: newNode.id,
        ...defaultEdgeOptions
      };

      // Use official addEdges function
      addEdges([newEdge]);
      emitFlowChanged();

      // Close menu after selection
      closeChildNodeMenu();
    };

    // ============================================================================
    // NODE ACTIONS MENU
    // ============================================================================

    // Show actions menu (3-dots button)
    const showActionsMenu = (nodeId, event) => {
      event.preventDefault();
      event.stopPropagation();

      // Close child menu if open
      closeChildNodeMenu();

      actionsMenu.nodeId = nodeId;
      actionsMenu.x = event.clientX;
      actionsMenu.y = event.clientY;
      actionsMenu.visible = true;
    };

    // Close actions menu
    const closeActionsMenu = () => {
      actionsMenu.visible = false;
      actionsMenu.nodeId = null;
    };

    // Duplicate node
    const duplicateNode = () => {
      const nodeId = actionsMenu.nodeId;
      if (!nodeId) return;

      const node = nodes.value.find(n => n.id === nodeId);
      if (!node) return;

      // Deselect original node
      node.selected = false;

      const newNode = {
        ...node,
        id: uuidv4(),
        data: JSON.parse(JSON.stringify(node.data)), // Deep clone data
        position: {
          x: node.position.x + DUPLICATE_OFFSET,
          y: node.position.y + DUPLICATE_OFFSET
        },
        selected: true // Highlight duplicated node
      };

      addNodes([newNode]);
      emitFlowChanged();
      showToast('Sucesso', 'Nó duplicado com sucesso', ToastTypes.SUCCESS, 1500);
      closeActionsMenu();
    };


    // Auto-Layout: Toggle between horizontal and vertical layouts
    const layoutOrientation = ref('horizontal'); // Track current orientation

    const autoLayout = () => {
      try {
        logger.log('🎨 Auto-Layout iniciado!');
        logger.log('📊 Nodes:', nodes.value.length, 'Edges:', edges.value.length);

        if (nodes.value.length === 0) {
          showToast('Aviso', 'Nenhum nó para organizar', ToastTypes.WARNING, 2000);
          return;
        }

        // Save current state for undo
        saveHistory();

        // Toggle orientation on each click
        layoutOrientation.value = layoutOrientation.value === 'horizontal' ? 'vertical' : 'horizontal';
        const isHorizontal = layoutOrientation.value === 'horizontal';

        logger.log('🎨 Iniciando auto-layout', isHorizontal ? 'HORIZONTAL' : 'VERTICAL', 'de', nodes.value.length, 'nós');

      // Configuration - adapts based on orientation
      const LEVEL_GAP = 350;        // Gap between levels
      const NODE_GAP = 100;         // Gap between nodes in same level
      const START_X = 100;
      const START_Y = 100;

      // Build adjacency map (nodeId -> array of child nodeIds)
      const adjacencyMap = new Map();
      const inDegree = new Map();

      // Initialize maps
      nodes.value.forEach(node => {
        adjacencyMap.set(node.id, []);
        inDegree.set(node.id, 0);
      });

      // Populate adjacency map and in-degree count
      // CRITICAL: Sort children by branch index for traffic nodes to maintain order
      edges.value.forEach(edge => {
        const children = adjacencyMap.get(edge.source) || [];
        children.push({
          nodeId: edge.target,
          sourceHandle: edge.sourceHandle || null,
          branchIndex: edge.sourceHandle ? parseInt(edge.sourceHandle.split('-output-')[1]) : 0
        });
        adjacencyMap.set(edge.source, children);
        inDegree.set(edge.target, (inDegree.get(edge.target) || 0) + 1);
      });

      // Sort children by branch index for each parent
      adjacencyMap.forEach((children, nodeId) => {
        const node = nodes.value.find(n => n.id === nodeId);
        // For traffic nodes, sort by branch index to maintain visual order
        if (node?.type === NodeTypes.TRAFFIC) {
          children.sort((a, b) => a.branchIndex - b.branchIndex);
        }
      });

      // Find root nodes (nodes with no incoming edges or type 'start')
      const rootNodes = nodes.value.filter(node =>
        node.type === NodeTypes.START || inDegree.get(node.id) === 0
      );

      if (rootNodes.length === 0) {
        logger.warn('⚠️ Nenhum nó raiz encontrado, usando primeiro nó');
        rootNodes.push(nodes.value[0]);
      }

      logger.log('🌳 Nós raiz encontrados:', rootNodes.length);

      // BFS to organize nodes in levels
      const levels = [];
      const visited = new Set();
      const queue = rootNodes.map(node => ({ id: node.id, level: 0 }));

      rootNodes.forEach(node => visited.add(node.id));

      while (queue.length > 0) {
        const { id, level } = queue.shift();

        // Initialize level array if needed
        if (!levels[level]) {
          levels[level] = [];
        }

        levels[level].push(id);

        // Add children to queue (now children are objects with nodeId and branchIndex)
        const children = adjacencyMap.get(id) || [];
        children.forEach(child => {
          const childId = child.nodeId;
          if (!visited.has(childId)) {
            visited.add(childId);
            queue.push({ id: childId, level: level + 1 });
          }
        });
      }

      // Handle orphan nodes (not connected to root)
      const orphans = nodes.value.filter(node => !visited.has(node.id));
      if (orphans.length > 0) {
        logger.log('🏝️ Nós órfãos encontrados:', orphans.length);
        if (!levels[levels.length]) {
          levels[levels.length] = [];
        }
        orphans.forEach(node => levels[levels.length - 1].push(node.id));
      }

      logger.log('📊 Níveis criados:', levels.length);
      levels.forEach((level, idx) => {
        logger.log(`  Nível ${idx}:`, level.length, 'nós');
      });

      // Calculate positions - adapts to orientation
      const newPositions = new Map();
      const nodeMap = new Map(nodes.value.map(node => [node.id, node]));

      // Helper function to get node dimensions
      const getNodeDimensions = (nodeId) => {
        const node = nodeMap.get(nodeId);
        return {
          width: node?.dimensions?.width || UI_SIZES.NODE_DEFAULT_WIDTH,
          height: node?.dimensions?.height || UI_SIZES.NODE_DEFAULT_HEIGHT
        };
      };

      levels.forEach((levelNodes, levelIndex) => {
        if (isHorizontal) {
          // HORIZONTAL layout (left to right, top to bottom within level)
          const x = START_X + (levelIndex * LEVEL_GAP);

          // Calculate total height needed for this level
          const levelHeights = levelNodes.map(nodeId => getNodeDimensions(nodeId).height);
          const totalLevelHeight = levelHeights.reduce((sum, height) => sum + height, 0) +
                                  (levelNodes.length - 1) * NODE_GAP;

          // Center the level vertically
          let currentY = START_Y - (totalLevelHeight / 2);

          levelNodes.forEach((nodeId) => {
            const nodeDimensions = getNodeDimensions(nodeId);
            newPositions.set(nodeId, { x, y: currentY });
            currentY += nodeDimensions.height + NODE_GAP;
          });
        } else {
          // VERTICAL layout (top to bottom, left to right within level)
          const y = START_Y + (levelIndex * LEVEL_GAP);

          // Calculate total width needed for this level
          const levelWidths = levelNodes.map(nodeId => getNodeDimensions(nodeId).width);
          const totalLevelWidth = levelWidths.reduce((sum, width) => sum + width, 0) +
                                 (levelNodes.length - 1) * NODE_GAP;

          // Center the level horizontally
          let currentX = START_X - (totalLevelWidth / 2);

          levelNodes.forEach((nodeId) => {
            const nodeDimensions = getNodeDimensions(nodeId);
            newPositions.set(nodeId, { x: currentX, y });
            currentX += nodeDimensions.width + NODE_GAP;
          });
        }
      });

      // Apply new positions - mutate nodes directly to maintain reactivity
      nodes.value.forEach(node => {
        const newPos = newPositions.get(node.id);
        if (newPos) {
          node.position.x = newPos.x;
          node.position.y = newPos.y;
        }
      });

      logger.log('📍 Positions updated, emitting changes...');
      emitFlowChanged();

      // Auto-fit view to show all nodes
      safeSetTimeout(() => {
        if (fitView) {
          fitView({ padding: 0.2, duration: 300 });
        }
      }, 100);

        const orientationIcon = isHorizontal ? '↔️' : '↕️';
        const orientationText = isHorizontal ? 'Horizontal' : 'Vertical';
        showToast(
          `Layout ${orientationText} ${orientationIcon}`,
          `${nodes.value.length} nós organizados em ${levels.length} níveis`,
          ToastTypes.SUCCESS,
          3000
        );

        logger.log('✅ Auto-layout concluído com sucesso!');
      } catch (error) {
        logger.error('❌ Erro no auto-layout:', error);
        showToast('Erro', `Falha ao aplicar layout: ${error.message}`, ToastTypes.ERROR, 5000);
      }
    };

    // Refresh canvas: Reloads visual without losing data
    const refreshCanvas = () => {
      try {
        logger.log('🔄 Refreshing canvas...');

        // Store current flow data
        const currentNodes = [...nodes.value];
        const currentEdges = [...edges.value];

        // Clear canvas temporarily
        removeNodes(nodes.value);
        removeEdges(edges.value);

        // Re-add nodes and edges (this forces a re-render)
        nextTick(() => {
          addNodes(currentNodes);
          addEdges(currentEdges);

          // Fit view after refresh
          safeSetTimeout(() => {
            if (fitView) {
              fitView({ padding: 0.2, duration: 300 });
            }
            showToast('Atualizado', 'Canvas recarregado com sucesso', ToastTypes.SUCCESS, 2000);
            logger.log('✅ Canvas refreshed successfully');
          }, 50);
        });
      } catch (error) {
        logger.error('❌ Error refreshing canvas:', error);
        showToast('Erro', `Falha ao atualizar: ${error.message}`, ToastTypes.ERROR, 3000);
      }
    };

    // Prevent duplicate keyboard event handling
    let lastKeyEventTime = 0;
    const KEYBOARD_THROTTLE_MS = 100; // 100ms throttle for keyboard events

    const handleKeyDown = (event) => {
      // Only handle keyboard shortcuts when not typing in an input
      if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA' || event.target.tagName === 'SELECT') {
        return;
      }

      // CRITICAL FIX: Only handle events if this component instance is actually visible
      // WeWeb may load multiple instances across different pages/frames
      const container = vueFlowRef.value?.$el || vueFlowRef.value;
      if (!container) {
        logger.log('⏭️ Ignoring keyboard event - component not mounted yet');
        return;
      }

      // Check if component is visible in viewport
      const rect = container.getBoundingClientRect();
      const isVisible = rect.width > 0 && rect.height > 0 && rect.top < window.innerHeight && rect.bottom > 0;

      if (!isVisible) {
        logger.log('⏭️ Ignoring keyboard event - component not visible (UID:', props.uid, ')');
        return;
      }

      // Additional check: Only handle if this component has focus or contains the active element
      const doc = wwLib.getFrontDocument() || document;
      const activeElement = doc.activeElement;
      const hasFocus = container.contains(activeElement) || container === activeElement;

      if (!hasFocus && event.code !== 'Space') {
        // Allow Space for panning even without focus, but require focus for other shortcuts
        logger.log('⏭️ Ignoring keyboard event - component does not have focus (UID:', props.uid, ')');
        return;
      }

      logger.log('✅ Handling keyboard event in component UID:', props.uid);

      // Space key: Enable panning mode (no throttling needed - state-based)
      if (event.code === 'Space' && !isSpacePressed.value) {
        event.preventDefault();
        isSpacePressed.value = true;
        return;
      }

      // Throttle all other keyboard shortcuts to prevent duplicate handling
      const now = Date.now();
      if (now - lastKeyEventTime < KEYBOARD_THROTTLE_MS) {
        logger.log('⏭️ Keyboard event throttled (duplicate within 100ms)');
        return;
      }
      lastKeyEventTime = now;

      const isMac = navigator.userAgent.toUpperCase().indexOf('MAC') >= 0;
      const ctrlOrCmd = isMac ? event.metaKey : event.ctrlKey;

      // Undo: Ctrl/Cmd + Z
      if (ctrlOrCmd && event.key === 'z' && !event.shiftKey) {
        event.preventDefault();
        undo();
        return;
      }

      // Redo: Ctrl/Cmd + Shift + Z or Ctrl/Cmd + Y
      if ((ctrlOrCmd && event.shiftKey && event.key === 'z') || (ctrlOrCmd && event.key === 'y')) {
        event.preventDefault();
        redo();
        return;
      }

      // Copy: Ctrl/Cmd + C
      if (ctrlOrCmd && event.key === 'c') {
        event.preventDefault();
        copySelectedNodes();
        return;
      }

      // Paste: Ctrl/Cmd + V
      if (ctrlOrCmd && event.key === 'v') {
        event.preventDefault();
        pasteNodes();
        return;
      }

      // Escape: Close sidebar
      if (event.key === 'Escape') {
        event.preventDefault();
        if (editingSidebar.visible) {
          closeEditSidebar();
          showToast('Cancelado', 'Edição cancelada', ToastTypes.INFO, 1500);
        } else {
          // Deselect all
          nodes.value.forEach(n => n.selected = false);
          edges.value.forEach(e => e.selected = false);
        }
        return;
      }

      // Delete/Backspace: Delete selected items
      if (event.key === 'Delete' || event.key === 'Backspace') {
        event.preventDefault();

        logger.log('🔑 Delete/Backspace pressed');
        logger.log('📊 Total nodes:', nodes.value.length);
        logger.log('📊 Total edges:', edges.value.length);

        saveHistory(); // Save before deleting

        const selectedNodes = nodes.value.filter(n => n.selected);
        const selectedEdges = edges.value.filter(e => e.selected);

        logger.log('📊 Selected nodes:', selectedNodes.length);
        logger.log('📊 Selected edges:', selectedEdges.length);

        // If nodes are selected, delete them (edges will be removed automatically)
        if (selectedNodes.length > 0) {
          // Confirm if deleting multiple nodes
          if (selectedNodes.length > 1) {
            const confirmed = wwLib.getFrontWindow().confirm(
              `Tem certeza que deseja excluir ${selectedNodes.length} nós?\n\nEsta ação não pode ser desfeita (use Ctrl/Cmd+Z para desfazer).`
            );
            if (!confirmed) {
              logger.log('❌ Deletion cancelled by user');
              return;
            }
          }

          logger.log('🗑️ Deleting', selectedNodes.length, 'nodes (connected edges will be removed automatically)');
          // Use official removeNodes - automatically removes ALL connected edges
          removeNodes(selectedNodes);
          emitFlowChanged();
          showToast('Excluído', `${selectedNodes.length} nó(s) excluído(s)`, ToastTypes.SUCCESS, 2000);
        }
        // If only edges are selected (no nodes), delete just the edges
        else if (selectedEdges.length > 0) {
          logger.log('🗑️ Deleting', selectedEdges.length, 'edges only');
          // Use official removeEdges
          removeEdges(selectedEdges);
          emitFlowChanged();
          showToast('Excluído', `${selectedEdges.length} conexão(ões) excluída(s)`, ToastTypes.SUCCESS, 2000);
        }
      }
    };

    const handleKeyUp = (event) => {
      // Space key: Disable panning mode
      if (event.code === 'Space' && isSpacePressed.value) {
        event.preventDefault();
        isSpacePressed.value = false;
      }
    };

    const editNode = (nodeId) => {
      const node = nodes.value.find(n => n.id === nodeId);
      if (!node || node.type === NodeTypes.START) return;

      // CRITICAL: Validate node.data to prevent "Cannot convert undefined or null to object"
      if (!node.data || typeof node.data !== 'object') {
        logger.error(`❌ Tentativa de editar nó com 'data' inválido (ID: ${nodeId}, tipo: ${node.type})`);
        showToast('Erro', 'Nó com dados corrompidos. Não é possível editar.', ToastTypes.ERROR, 3000);
        return;
      }

      editingSidebar.visible = true;
      editingSidebar.node = node;
      // SAFETY: Use fallback empty object if node.data is null/undefined (defensive programming)
      editingSidebar.data = { ...(node.data || {}) };

      // BACKWARD COMPATIBILITY: Set default imageAspectRatio for old cards
      if (node.type === NodeTypes.CARD && !editingSidebar.data.imageAspectRatio) {
        editingSidebar.data.imageAspectRatio = 'square';
      }
    };

    const saveNodeEdit = async () => {
      if (!editingSidebar.node) return;

      // Validate traffic node percentages
      if (editingSidebar.node.type === NodeTypes.TRAFFIC) {
        const total = getTotalPercentage();
        if (total !== 100) {
          showToast('Validação falhou', `Total deve ser 100% (atual: ${total}%)`, ToastTypes.ERROR, 3000);
          return; // Don't save or close sidebar
        }
      }

      // Validate card title (required)
      if (editingSidebar.node.type === NodeTypes.CARD && !editingSidebar.data.title) {
        showToast('Campo obrigatório', 'O título do card é obrigatório', ToastTypes.ERROR, 3000);
        return;
      }

      // Nielsen #5: Error Prevention - Check for duplicate content
      if (editingSidebar.node.type === NodeTypes.TEXT && editingSidebar.data.text) {
        const duplicateTextNode = nodes.value.find(n =>
          n.id !== editingSidebar.node.id &&
          n.type === NodeTypes.TEXT &&
          n.data?.text?.trim().toLowerCase() === editingSidebar.data.text.trim().toLowerCase()
        );

        if (duplicateTextNode) {
          const proceed = await showConfirm(
            `⚠️ Já existe outro nó de texto com conteúdo idêntico.\n\nTexto: "${editingSidebar.data.text.substring(0, 50)}..."\n\nDeseja criar duplicata mesmo assim?`,
            'Conteúdo Duplicado Detectado'
          );
          if (!proceed) {
            showToast('Cancelado', 'Edição cancelada', ToastTypes.INFO, 1500);
            return;
          }
        }
      }

      if (editingSidebar.node.type === NodeTypes.CARD && editingSidebar.data.title) {
        const duplicateCardNode = nodes.value.find(n =>
          n.id !== editingSidebar.node.id &&
          n.type === NodeTypes.CARD &&
          n.data?.title?.trim().toLowerCase() === editingSidebar.data.title.trim().toLowerCase() &&
          n.data?.imageUrl === editingSidebar.data.imageUrl
        );

        if (duplicateCardNode) {
          const proceed = await showConfirm(
            `⚠️ Já existe outro card com título e imagem idênticos.\n\nTítulo: "${editingSidebar.data.title}"\n\nDeseja criar duplicata mesmo assim?`,
            'Card Duplicado Detectado'
          );
          if (!proceed) {
            showToast('Cancelado', 'Edição cancelada', ToastTypes.INFO, 1500);
            return;
          }
        }
      }

      saveHistory(); // Save state before editing

      const oldData = { ...editingSidebar.node.data };

      // Update node data
      Object.assign(editingSidebar.node.data, editingSidebar.data);

      // Update label for display
      if (editingSidebar.node.type === NodeTypes.TEXT) {
        editingSidebar.node.data.label = editingSidebar.data.message?.substring(0, 30) + '...';
      }

      emit('trigger-event', {
        name: 'nodeEdited',
        event: {
          node: editingSidebar.node,
          nodeId: editingSidebar.node.id,
          oldData,
          newData: editingSidebar.node.data
        }
      });

      showToast('Salvo', 'Alterações salvas com sucesso', ToastTypes.SUCCESS, 2000);
      closeEditSidebar();
      emitFlowChanged();
    };

    const closeEditSidebar = () => {
      editingSidebar.visible = false;
      editingSidebar.node = null;
      editingSidebar.data = {};
    };

    const addButton = () => {
      if (!editingSidebar.data.buttons) {
        editingSidebar.data.buttons = [];
      }
      editingSidebar.data.buttons.push({
        id: uuidv4(), // UUID for stable v-for key
        label: '',
        action: 'send_message',
        message: '',
        url: ''
      });
    };

    const removeButton = (index) => {
      if (editingSidebar.data.buttons) {
        editingSidebar.data.buttons.splice(index, 1);
      }
    };

    const addBranch = () => {
      if (!editingSidebar.data.branches) {
        editingSidebar.data.branches = [];
      }
      editingSidebar.data.branches.push({
        id: uuidv4(), // UUID for stable v-for key
        label: `Opção ${editingSidebar.data.branches.length + 1}`,
        percentage: 50
      });
    };

    const removeBranch = (index) => {
      if (editingSidebar.data.branches && editingSidebar.data.branches.length > 1) {
        editingSidebar.data.branches.splice(index, 1);
      }
    };

    const distributeEquallyBranches = () => {
      const branches = editingSidebar.data.branches;
      if (!branches || branches.length === 0) {
        showToast('Sem opções', 'Adicione pelo menos uma opção para distribuir', ToastTypes.WARNING, 2000);
        return;
      }

      const equalPercentage = Math.floor(100 / branches.length);
      const remainder = 100 - (equalPercentage * branches.length);

      branches.forEach((branch, index) => {
        branch.percentage = equalPercentage;
        // Add remainder to last branch to ensure total = 100%
        if (index === branches.length - 1) {
          branch.percentage += remainder;
        }
      });

      showToast('Distribuído', `Percentuais distribuídos igualmente (${branches.length} opções)`, ToastTypes.SUCCESS, 2000);
    };

    const getTotalPercentage = () => {
      if (!editingSidebar.data.branches) return 0;
      return editingSidebar.data.branches.reduce((total, branch) => total + (branch.percentage || 0), 0);
    };

    const uploadImage = async (event) => {
      // Cancel previous upload if exists (HIGH-ROI: Abort Controller)
      uploadAbortController?.abort();
      uploadAbortController = new AbortController();

      // Race condition protection
      if (isProcessingUpload.value) {
        logger.warn('⚠️ Upload already in progress, ignoring duplicate call');
        return;
      }
      isProcessingUpload.value = true;

      try {
        const file = event.target.files[0];
        if (!file) return;

        // Validação 1: Verificar se é uma imagem
        if (!file.type.startsWith('image/')) {
          showToast('Erro', 'Apenas imagens são permitidas', ToastTypes.ERROR, 4000);
          logger.error('❌ Arquivo não é uma imagem:', file.type);
          return;
        }

        // Validação 2: Verificar tamanho (máximo 5MB)
        const MAX_SIZE = 5 * 1024 * 1024; // 5MB
        if (file.size > MAX_SIZE) {
          showToast('Erro', 'Imagem muito grande (máximo 5MB)', ToastTypes.ERROR, 4000);
          logger.error('❌ Imagem excede 5MB:', (file.size / 1024 / 1024).toFixed(2) + 'MB');
          return;
        }

        logger.log('📁 Uploading image:', file.name, `(${(file.size / 1024).toFixed(2)}KB)`);

        // Check if Supabase is configured
        if (!props.content?.supabaseUrl || !props.content?.supabaseAnonKey || !props.content?.supabaseBucket) {
          logger.warn('⚠️ Supabase not configured, using local data URL');
          showToast('Aviso', 'Supabase não configurado. Usando URL local.', ToastTypes.WARNING, 3000);
          // Fallback to local data URL
          const reader = new FileReader();
          reader.onload = (e) => {
            editingSidebar.data.imageUrl = e.target.result;
            showToast('Imagem carregada', 'Imagem adicionada localmente', ToastTypes.SUCCESS, 2000);
          };
          reader.readAsDataURL(file);
          return;
        }

        // Show loading toast
        const loadingToastId = showToast('Enviando...', 'Fazendo upload da imagem', ToastTypes.INFO, 0);

        try {
          // Generate unique filename
          const timestamp = Date.now();
          const randomString = Math.random().toString(36).substring(7);
          const fileExt = file.name.split('.').pop().toLowerCase();
          const fileName = `card-image-${timestamp}-${randomString}.${fileExt}`;
          const filePath = `public/${fileName}`;

          // Upload to Supabase Storage using upsert
          const response = await fetch(
            `${props.content?.supabaseUrl}/storage/v1/object/${props.content?.supabaseBucket}/${filePath}`,
            {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${props.content?.supabaseAnonKey}`,
                'apikey': props.content?.supabaseAnonKey,
                'Content-Type': file.type || 'application/octet-stream',
                'x-upsert': 'true'
              },
              body: file,
              signal: uploadAbortController.signal  // HIGH-ROI: Abort signal
            }
          );

          if (!response.ok) {
            const errorData = await response.text();
            logger.error('Upload error details:', errorData);
            throw new Error(`Upload failed: ${response.status} - ${errorData}`);
          }

          // Get public URL
          const publicUrl = `${props.content?.supabaseUrl}/storage/v1/object/public/${props.content?.supabaseBucket}/${filePath}`;

          // HIGH-ROI: Check if component still mounted before updating state
          if (!vueFlowRef.value) {
            logger.log('Upload completed but component unmounted - ignoring result');
            removeToast(loadingToastId);
            return;
          }

          logger.log('✅ Image uploaded successfully:', publicUrl);
          editingSidebar.data.imageUrl = publicUrl;

          // Remove loading toast and show success
          removeToast(loadingToastId);
          showToast('Sucesso', 'Imagem enviada com sucesso!', ToastTypes.SUCCESS, 3000);

          // Emit event for successful upload
          emit('trigger-event', {
            name: 'imageUploaded',
            event: {
              fileName,
              url: publicUrl,
              nodeId: editingSidebar.node?.id
            }
          });

        } catch (error) {
          // HIGH-ROI: Handle abort errors gracefully
          if (error.name === 'AbortError') {
            logger.log('Upload aborted');
            removeToast(loadingToastId);
            return;
          }

          logger.error('❌ Error uploading image:', error);

          // Remove loading toast and show error
          removeToast(loadingToastId);
          showToast('Erro no upload', 'Verifique as configurações do Supabase', ToastTypes.ERROR, 4000);

          // Clear the file input
          event.target.value = '';
        }
      } finally {
        isProcessingUpload.value = false;
      }
    };

    // Função para cores das branches
    const getBranchColor = (index) => {
      const colors = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];
      return colors[index % colors.length];
    };

    // Helper: Gerar objeto flowData (DRY - evita duplicação)
    const getFlowData = () => {
      return {
        nodes: nodes.value.map(node => ({
          id: node.id,
          type: node.type,
          x: node.position.x,
          y: node.position.y,
          data: node.data
        })),
        connections: edges.value.map(edge => ({
          from: edge.source,
          to: edge.target,
          sourceHandle: edge.sourceHandle || null,
          targetHandle: edge.targetHandle || null
        }))
      };
    };

    // Undo/Redo system
    const saveHistory = () => {
      const state = {
        nodes: JSON.parse(JSON.stringify(nodes.value)),
        edges: JSON.parse(JSON.stringify(edges.value))
      };

      // Remove future history if we're not at the end
      if (historyIndex.value < history.value.length - 1) {
        history.value = history.value.slice(0, historyIndex.value + 1);
      }

      history.value.push(state);

      // Limit history size
      if (history.value.length > maxHistorySize) {
        history.value.shift();
      }

      // Always increment index after adding to history
      historyIndex.value++;
    };

    const undo = () => {
      if (historyIndex.value > 0) {
        historyIndex.value--;
        const state = history.value[historyIndex.value];

        // Use official VueFlow API instead of direct assignment
        const allNodes = [...nodes.value];
        const allEdges = [...edges.value];

        if (allNodes.length > 0) removeNodes(allNodes);
        if (allEdges.length > 0) removeEdges(allEdges);

        const restoredNodes = JSON.parse(JSON.stringify(state.nodes));
        const restoredEdges = JSON.parse(JSON.stringify(state.edges));

        if (restoredNodes.length > 0) addNodes(restoredNodes);
        if (restoredEdges.length > 0) addEdges(restoredEdges);

        emitFlowChanged();
        showToast('Desfeito', 'Ação desfeita com sucesso', ToastTypes.INFO, 2000);
      } else {
        showToast('Impossível desfazer', 'Não há mais ações para desfazer', ToastTypes.WARNING, 2000);
      }
    };

    const redo = () => {
      if (historyIndex.value < history.value.length - 1) {
        historyIndex.value++;
        const state = history.value[historyIndex.value];

        // Use official VueFlow API instead of direct assignment
        const allNodes = [...nodes.value];
        const allEdges = [...edges.value];

        if (allNodes.length > 0) removeNodes(allNodes);
        if (allEdges.length > 0) removeEdges(allEdges);

        const restoredNodes = JSON.parse(JSON.stringify(state.nodes));
        const restoredEdges = JSON.parse(JSON.stringify(state.edges));

        if (restoredNodes.length > 0) addNodes(restoredNodes);
        if (restoredEdges.length > 0) addEdges(restoredEdges);

        emitFlowChanged();
        showToast('Refeito', 'Ação refeita com sucesso', ToastTypes.INFO, 2000);
      } else {
        showToast('Impossível refazer', 'Não há mais ações para refazer', ToastTypes.WARNING, 2000);
      }
    };

    // Copy/paste system
    const clipboard = ref(null);

    const copySelectedNodes = () => {
      logger.log('📋 copySelectedNodes called - Component UID:', props.uid);
      logger.log('📋 Call stack:', new Error().stack);

      const selectedNodes = nodes.value.filter(n => n.selected);
      if (selectedNodes.length === 0) {
        showToast('Nada selecionado', 'Selecione um ou mais nós para copiar', ToastTypes.WARNING, 2000);
        return;
      }

      // Filter out START nodes (can't be copied)
      const copyableNodes = selectedNodes.filter(n => n.type !== NodeTypes.START);

      if (copyableNodes.length === 0) {
        showToast('Nó START não pode ser copiado', 'Selecione outros tipos de nós', ToastTypes.WARNING, 2000);
        return;
      }

      // Also copy edges between selected nodes
      const copyableNodeIds = new Set(copyableNodes.map(n => n.id));
      const selectedEdges = edges.value.filter(e =>
        copyableNodeIds.has(e.source) && copyableNodeIds.has(e.target)
      );

      clipboard.value = {
        nodes: JSON.parse(JSON.stringify(copyableNodes)),
        edges: JSON.parse(JSON.stringify(selectedEdges))
      };

      // Show single toast with combined message if START nodes were filtered
      const startNodesCount = selectedNodes.length - copyableNodes.length;
      logger.log('📋 Showing copy toast:', { copyable: copyableNodes.length, startFiltered: startNodesCount });

      if (startNodesCount > 0) {
        showToast(
          'Copiado',
          `${copyableNodes.length} nó(s) copiado(s) • ${startNodesCount} nó(s) START ignorado(s)`,
          ToastTypes.SUCCESS,
          2500
        );
      } else {
        showToast('Copiado', `${copyableNodes.length} nó(s) copiado(s)`, ToastTypes.SUCCESS, 2000);
      }
    };

    const pasteNodes = () => {
      if (!clipboard.value || clipboard.value.nodes.length === 0) {
        showToast('Área de transferência vazia', 'Copie alguns nós primeiro', ToastTypes.WARNING, 2000);
        return;
      }

      // Filter out START nodes (double-check in case clipboard was tampered with)
      const pasteableNodes = clipboard.value.nodes.filter(n => n.type !== NodeTypes.START);

      if (pasteableNodes.length === 0) {
        showToast('Nó START não pode ser colado', 'Nenhum nó válido para colar', ToastTypes.WARNING, 2000);
        return;
      }

      saveHistory();

      // Create ID mapping for old to new IDs
      const idMap = new Map();

      // Paste nodes with offset
      const pastedNodes = pasteableNodes.map(node => {
        const newId = uuidv4();
        idMap.set(node.id, newId);

        return {
          ...node,
          id: newId,
          position: {
            x: node.position.x + DUPLICATE_OFFSET,
            y: node.position.y + DUPLICATE_OFFSET
          },
          selected: true
        };
      });

      // Deselect all existing nodes and edges
      nodes.value.forEach(n => n.selected = false);
      edges.value.forEach(e => e.selected = false);

      // Add pasted nodes using official addNodes function
      addNodes(pastedNodes);

      // Paste edges with new IDs
      const pastedEdges = clipboard.value.edges.map(edge => ({
        ...edge,
        id: `edge-${uuidv4()}`,
        source: idMap.get(edge.source),
        target: idMap.get(edge.target),
        selected: false // Ensure pasted edges are not selected
      }));

      // Use official addEdges function
      addEdges(pastedEdges);

      emitFlowChanged();
      showToast('Colado', `${pastedNodes.length} nó(s) colado(s)`, ToastTypes.SUCCESS, 2000);
    };

    // Flow management
    const loadDefaultFlow = () => {
      logger.log('📝 Creating default flow with start node...');

      const startNode = {
        id: uuidv4(),
        type: NodeTypes.START,
        position: { x: 200, y: 200 },
        data: getDefaultNodeData(NodeTypes.START),
        selectable: true,
        draggable: true
      };

      // Clear existing nodes/edges using official functions
      const allNodes = [...nodes.value];
      const allEdges = [...edges.value];
      if (allNodes.length > 0) removeNodes(allNodes);
      if (allEdges.length > 0) removeEdges(allEdges);

      // Add start node using official function
      addNodes([startNode]);

      logger.log('✅ Vue Flow example loaded successfully');
      logger.log('📋 Nodes loaded:', nodes.value);
      logger.log('🔗 Edges loaded:', edges.value);
      emitFlowChanged();

      // Fit view after nodes are added
      safeSetTimeout(() => {
        fitView();
      }, 100);
    };

    const clearFlow = async () => {
      // Race condition protection
      if (isProcessingClear.value) {
        logger.warn('⚠️ Clear already in progress, ignoring duplicate call');
        return;
      }
      isProcessingClear.value = true;

      try {
        const confirmed = await showConfirm(
          'Tem certeza que deseja limpar todo o fluxo? Esta ação não pode ser desfeita.',
          'Limpar Fluxo'
        );

        if (confirmed) {
        // Clear existing nodes/edges using official functions
        const allNodes = [...nodes.value];
        const allEdges = [...edges.value];
        if (allNodes.length > 0) removeNodes(allNodes);
        if (allEdges.length > 0) removeEdges(allEdges);

        // Create default start node
        const startNode = {
          id: uuidv4(),
          type: NodeTypes.START,
          position: { x: 200, y: 200 },
          data: getDefaultNodeData(NodeTypes.START),
          selectable: true,
          draggable: true
        };

        // Add start node using official function
        addNodes([startNode]);

        closeEditSidebar();
        emitFlowChanged();
        showToast('Fluxo limpo', 'O fluxo foi resetado com sucesso', ToastTypes.SUCCESS, 2000);
      }
      } finally {
        isProcessingClear.value = false;
      }
    };

    const zoomToFit = () => {
      fitView();
    };

    // Função para validar a integridade do fluxo
    const validateFlow = () => {
      const warnings = [];
      const errors = [];

      // 1. Verificar se existe node de início (using helper functions)
      const startNodes = getStartNodes();
      if (startNodes.length === 0) {
        errors.push('❌ Fluxo sem node de "Início". Todo fluxo precisa começar em algum lugar.');
      } else if (hasMultipleStartNodes()) {
        warnings.push(`⚠️ Existem ${startNodes.length} nodes de "Início". Isto criará ${startNodes.length} fluxos separados.`);
      }

      // 2. Verificar nodes órfãos (sem conexões)
      nodes.value.forEach(node => {
        const hasIncoming = edges.value.some(e => e.target === node.id);
        const hasOutgoing = edges.value.some(e => e.source === node.id);

        if (node.type === NodeTypes.START) {
          // Node de início não deve ter entrada, mas deve ter saída
          if (!hasOutgoing) {
            warnings.push(`⚠️ Node de "Início" (${node.id}) não tem conexões de saída.`);
          }
        } else {
          // Outros nodes devem ter pelo menos entrada
          if (!hasIncoming && !hasOutgoing) {
            warnings.push(`⚠️ Node "${node.data?.label || node.type}" está órfão (sem conexões).`);
          } else if (!hasIncoming) {
            warnings.push(`⚠️ Node "${node.data?.label || node.type}" não tem conexão de entrada.`);
          }
        }

        // Verificar nodes sem saída (possíveis pontos finais)
        if (!hasOutgoing && node.type !== NodeTypes.START) {
          // Isto é OK - são pontos finais do fluxo
          // Apenas informativo
        }
      });

      // 3. Validação específica: Divisor de Tráfego (usando função centralizada)
      nodes.value.forEach(node => {
        const branchIssues = validateTrafficBranches(node, edges.value, false);
        branchIssues.forEach(issue => {
          warnings.push(`⚠️ Divisor de Tráfego: ${issue}`);
        });
      });

      return { warnings, errors, isValid: errors.length === 0 };
    };

    // ============================================================================
    // CENTRALIZED VALIDATION: Traffic Node Branches
    // ============================================================================
    // This function is used by both validateFlow() and validationState computed
    // to ensure consistent validation logic across the application.
    // DRY Principle: Single source of truth for traffic branch validation.
    const validateTrafficBranches = (node, edgesOrHandleIndex, useHandleIndex = false) => {
      const issues = [];

      if (node.type !== NodeTypes.TRAFFIC || !node.data?.branches) {
        return issues;
      }

      const branches = node.data.branches;

      // Validation 1: Check if all branches sum to 100%
      const total = branches.reduce((sum, b) => sum + (b.percentage || 0), 0);
      if (total !== 100) {
        issues.push(`Porcentagens somam ${total}% (deve ser 100%)`);
      }

      // Validation 2: Check if each branch is connected
      branches.forEach((branch, index) => {
        const branchHandleId = `${node.id}-output-${index}`;
        let hasConnection = false;

        if (useHandleIndex) {
          // O(1) lookup using handleIndex Map (for validationState)
          const handleKey = `${node.id}-output-${index}`;
          hasConnection = edgesOrHandleIndex.has(handleKey);
        } else {
          // O(M) linear search using edges array (for validateFlow)
          hasConnection = edgesOrHandleIndex.some(
            e => e.source === node.id && e.sourceHandle === branchHandleId
          );
        }

        if (!hasConnection) {
          issues.push(`Branch "${branch.label}" não conectado`);
        }
      });

      return issues;
    };

    // PERFORMANCE OPTIMIZATION: Cached validation state for all nodes
    // This computed property calculates validation for ALL nodes at once when nodes or edges change.
    // CRITICAL OPTIMIZATION: Uses edge indexes for O(1) lookup instead of O(M) linear search.
    // Complexity: O(N + M) instead of O(N × M × B)
    // With 100 nodes, 200 edges, 5 branches: 300 operations instead of 100,000!
    const validationState = computed(() => {
      const state = new Map();

      // CREATE INDEXES: O(M) - Build edge lookup maps for instant access
      // This transforms expensive .some() calls into O(1) Set.has() lookups
      const incomingIndex = new Map(); // nodeId -> Set of incoming edges
      const outgoingIndex = new Map(); // nodeId -> Set of outgoing edges
      const handleIndex = new Map();   // "nodeId-sourceHandle" -> edge exists

      edges.value.forEach(edge => {
        // Index incoming edges
        if (!incomingIndex.has(edge.target)) {
          incomingIndex.set(edge.target, new Set());
        }
        incomingIndex.get(edge.target).add(edge);

        // Index outgoing edges
        if (!outgoingIndex.has(edge.source)) {
          outgoingIndex.set(edge.source, new Set());
        }
        outgoingIndex.get(edge.source).add(edge);

        // Index by source handle for traffic node validation
        if (edge.sourceHandle) {
          handleIndex.set(edge.sourceHandle, true);
        }
      });

      // VALIDATE NODES: O(N) - Now each node validation is O(1) thanks to indexes
      for (const node of nodes.value) {
        const issues = [];
        let hasError = false;
        let hasWarning = false;

        // O(1) lookup instead of O(M)
        const hasIncoming = incomingIndex.has(node.id);
        const hasOutgoing = outgoingIndex.has(node.id);

        // Check node type specific validations
        if (node.type === NodeTypes.START) {
          if (!hasOutgoing) {
            issues.push('Sem conexões de saída');
            hasWarning = true;
          }
        } else {
          if (!hasIncoming && !hasOutgoing) {
            issues.push('Nó órfão (sem conexões)');
            hasWarning = true;
          } else if (!hasIncoming) {
            issues.push('Sem conexão de entrada');
            hasWarning = true;
          }
        }

        // Traffic node specific validation (usando função centralizada)
        const branchIssues = validateTrafficBranches(node, handleIndex, true);
        if (branchIssues.length > 0) {
          issues.push(...branchIssues);
          hasWarning = true;
        }

        state.set(node.id, { hasError, hasWarning, issues });
      }

      return state;
    });

    // Helper function for backwards compatibility and safe access
    const validateNode = (nodeId) => {
      return validationState.value.get(nodeId) || { hasError: false, hasWarning: false, issues: [] };
    };

    const saveFlow = async () => {
      // Race condition protection
      if (isProcessingSave.value) {
        logger.warn('⚠️ Save already in progress, ignoring duplicate call');
        return;
      }
      isProcessingSave.value = true;

      try {
        // Validar o fluxo antes de salvar
        const validation = validateFlow();

      if (validation.errors.length > 0) {
        const errorMsg = validation.errors.join('\n\n');
        showToast('Erro de validação', 'Corrija os erros antes de salvar', ToastTypes.ERROR, 4000);
        await showAlert(errorMsg, 'Erros de Validação');
        return;
      }

      if (validation.warnings.length > 0) {
        const warningMsg = validation.warnings.join('\n\n');
        const proceed = await showConfirm(warningMsg + '\n\nDeseja salvar mesmo assim?', 'Avisos de Validação');
        if (!proceed) {
          showToast('Cancelado', 'Salvamento cancelado', ToastTypes.INFO, 2000);
          return;
        }
      }

      const flowData = getFlowData();

      // Nielsen #5: Error Prevention - Mark as saved
      hasUnsavedChanges.value = false;
      lastSavedState.value = JSON.stringify(flowData);

      emit('trigger-event', {
        name: EventNames.FLOW_SAVED,
        event: {
          flowData,
          timestamp: new Date().toISOString(),
          validation
        }
      });

      // Show success toast
      showToast('Salvo com sucesso', 'Fluxo salvo com sucesso!', ToastTypes.SUCCESS, 3000);

      // Visual feedback (using WeWeb safe document access)
      const doc = wwLib.getFrontDocument();
      if (doc) {
        const originalTitle = doc.title;
        doc.title = '✓ Flow Saved!';
        safeSetTimeout(() => {
          doc.title = originalTitle;
        }, 2000);
      }
      } finally {
        isProcessingSave.value = false;
      }
    };

    const exportFlow = () => {
      const flowData = getFlowData();

      emit('trigger-event', {
        name: EventNames.FLOW_EXPORTED,
        event: {
          flowData,
          format: 'json'
        }
      });

      // Download file (using WeWeb safe document access)
      const doc = wwLib.getFrontDocument();
      if (doc) {
        const blob = new Blob([JSON.stringify(flowData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = doc.createElement('a');
        a.href = url;
        a.download = 'messenger-flow.json';
        a.click();
        URL.revokeObjectURL(url);
        showToast('Exportado', 'Fluxo exportado com sucesso!', ToastTypes.SUCCESS, 3000);
      }
    };

    // Schema validation for imported flow data (Task 10)
    const validateFlowSchema = (data) => {
      const errors = [];

      // Check if data is an object
      if (!data || typeof data !== 'object') {
        errors.push('O arquivo deve conter um objeto JSON válido');
        return { valid: false, errors };
      }

      // Check for nodes array
      if (!Array.isArray(data.nodes)) {
        errors.push('O fluxo deve conter um array "nodes"');
      } else {
        // Validate each node
        data.nodes.forEach((node, index) => {
          if (!node.id) errors.push(`Nó ${index + 1} está sem ID`);
          if (!node.type) errors.push(`Nó ${index + 1} está sem tipo`);
          if (typeof node.x !== 'number' || typeof node.y !== 'number') {
            errors.push(`Nó ${index + 1} tem coordenadas inválidas`);
          }
          if (!node.data || typeof node.data !== 'object') {
            errors.push(`Nó ${index + 1} está sem dados`);
          }
        });
      }

      // Check for connections array
      if (!Array.isArray(data.connections)) {
        errors.push('O fluxo deve conter um array "connections"');
      } else {
        // Validate each connection
        data.connections.forEach((conn, index) => {
          if (!conn.from) errors.push(`Conexão ${index + 1} está sem origem (from)`);
          if (!conn.to) errors.push(`Conexão ${index + 1} está sem destino (to)`);
        });
      }

      return {
        valid: errors.length === 0,
        errors
      };
    };

    const importFlow = () => {
      // Using WeWeb safe document access
      const doc = wwLib.getFrontDocument();
      if (!doc) return;

      const input = doc.createElement('input');
      input.type = 'file';
      input.accept = '.json';

      input.onchange = (e) => {
        const file = e.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
          try {
            const flowData = JSON.parse(e.target.result);

            // Validate schema before importing (Task 10)
            const validation = validateFlowSchema(flowData);
            if (!validation.valid) {
              const errorMessage = `Schema inválido:\n${validation.errors.join('\n')}`;
              showToast('Erro de validação', errorMessage, ToastTypes.ERROR, 6000);
              logger.error('Flow validation failed:', validation.errors);
              return;
            }

            // Use loadFlowData to handle the import (don't skip emit)
            loadFlowData(flowData, false);

            emit('trigger-event', {
              name: EventNames.FLOW_IMPORTED,
              event: {
                flowData,
                nodesCount: flowData.nodes?.length || 0,
                connectionsCount: flowData.connections?.length || 0
              }
            });

            showToast('Importado', `${flowData.nodes?.length || 0} nó(s) importado(s)`, ToastTypes.SUCCESS, 3000);

          } catch (error) {
            showToast('Erro na importação', error.message, ToastTypes.ERROR, 4000);
            logger.error('Import error:', error);
          }
        };
        reader.readAsText(file);
      };

      input.click();
    };

    const emitFlowChanged = () => {
      // Don't emit if we're loading initial data
      if (isLoadingInitial.value) return;

      // CRITICAL FIX: Only emit if this instance is active
      // This prevents non-visible instances from triggering global workflows
      if (!isComponentActive()) {
        logger.log('⏭️ Skipping emitFlowChanged - component not active');
        return;
      }

      const flowData = getFlowData();

      // Nielsen #5: Error Prevention - Mark as unsaved
      hasUnsavedChanges.value = true;

      // Update content - DON'T include initialFlow to avoid loops
      const contentUpdate = { ...props.content };
      delete contentUpdate.initialFlow; // Remove initialFlow to avoid circular updates
      contentUpdate.flowData = flowData;

      emit('update:content', contentUpdate);

      // Emit event with instance metadata for isolation
      emit('trigger-event', {
        name: EventNames.FLOW_CHANGED,
        event: {
          // Instance metadata (NEW - for workflow isolation)
          componentUid: props.uid,
          isActive: true, // Always true here due to isComponentActive check
          timestamp: Date.now(),

          // Existing data
          nodes: nodes.value,
          edges: edges.value,
          flowData,
          hasUnsavedChanges: hasUnsavedChanges.value
        }
      });
    };

    // Create debounced version of emitFlowChanged for position changes
    const debouncedEmitFlowChanged = debounce(emitFlowChanged, 100);

    // Actions for WeWeb workflows
    const actions = {
      addNode: (args) => {
        addNode(args.nodeType, args.position);
      },
      removeNode: (args) => {
        deleteNode(args.nodeId);
      },
      clearFlow,
      exportFlow,
      importFlow: (args) => {
        if (args.flowData && typeof args.flowData === 'object') {
          loadFlowData(args.flowData);
          emit('trigger-event', {
            name: 'flowImported',
            event: {
              flowData: args.flowData,
              nodesCount: args.flowData.nodes?.length || 0,
              connectionsCount: args.flowData.connections?.length || 0
            }
          });
        }
      },
      zoomToFit,
      validateFlow: () => {
        const validation = validateFlow();

        emit('trigger-event', {
          name: 'flowValidated',
          event: { validation }
        });

        return validation;
      },
      getFlowStats: () => {
        const stats = {
          totalNodes: nodes.value.length,
          nodeTypes: nodes.value.reduce((acc, node) => {
            acc[node.type] = (acc[node.type] || 0) + 1;
            return acc;
          }, {}),
          totalConnections: edges.value.length
        };

        emit('trigger-event', {
          name: 'flowStats',
          event: { stats }
        });

        return stats;
      }
    };

    // Expose actions to WeWeb (using safe window access)
    const win = wwLib.getFrontWindow();
    if (win) {
      win[`wwElement_${props.uid}_actions`] = actions;
    }

    return {
      // ============================================================================
      // 1. ENUMS & CONSTANTS (Imutáveis - Referência)
      // ============================================================================
      Position,
      MarkerType,
      ConnectionLineType,
      NodeTypes,
      EventNames,
      ToastTypes,
      Colors,
      Distances,
      UI_SIZES,
      HELPER_LINES,
      Z_INDEX,

      // ============================================================================
      // 2. REACTIVE STATE (Refs & Reactives)
      // ============================================================================
      // Core flow state
      nodes,
      edges,
      
      // UI state
      editingSidebar,
      isDockCollapsed,
      hoveredEdge,
      isSpacePressed,
      childNodeMenu,
      actionsMenu,
      
      // Feedback systems
      toasts,
      dialogState,
      tooltipState,
      
      // Visual helpers
      helperLines,
      helperLinesCanvasRef,
      connectionPreview,

      // ============================================================================
      // 3. COMPUTED PROPERTIES (Derivados)
      // ============================================================================
      availableComponents,
      actionsMenuNode,
      validationState,
      connectionLineStyle,

      // ============================================================================
      // 4. VUEFLOW NATIVE API (Funções da biblioteca)
      // ============================================================================
      addNodes,
      removeNodes,
      addEdges,
      removeEdges,

      // ============================================================================
      // 5. EVENT HANDLERS (Callbacks de eventos)
      // ============================================================================
      // Flow events
      onNodesChange,
      onEdgesChange,
      onConnect,
      onConnectStart,
      onConnectEnd,
      isValidConnection,
      onNodeDrag,
      onNodeDragStop,
      onPaneClick,
      
      // Drag & drop events
      onDockItemClick,
      onDragStart,
      onDragEnd,
      onDragOver,
      onDrop,

      // ============================================================================
      // 6. BUSINESS LOGIC METHODS (Métodos de negócio)
      // ============================================================================
      // Node management
      addNode,
      deleteNode,
      editNode,
      saveNodeEdit,
      duplicateNode,
      
      // Edge management
      deleteEdge,
      handleEdgeHover,
      
      // Menu management
      showChildNodeMenu,
      closeChildNodeMenu,
      createChildNode,
      showActionsMenu,
      closeActionsMenu,
      
      // Sidebar editing
      closeEditSidebar,
      addButton,
      removeButton,
      addBranch,
      removeBranch,
      distributeEquallyBranches,
      getTotalPercentage,

      // Flow operations
      clearFlow,
      saveFlow,
      exportFlow,
      importFlow,
      autoLayout,
      refreshCanvas,
      zoomToFit,

      // Validation
      validateFlow,
      validateNode,
      
      // History (Undo/Redo)
      undo,
      redo,
      
      // Change tracking
      emitFlowChanged,

      // ============================================================================
      // 7. UTILITY METHODS (Helpers e utilitários)
      // ============================================================================
      // UI feedback
      removeToast,
      closeDialog,
      showTooltip,
      hideTooltip,
      
      // Visual helpers
      getConnectionPath,
      getConnectionStrokeColor,
      getBranchColor,
      
      // File operations
      uploadImage,
      
      // Edge options
      defaultEdgeOptions
    };
  }
};
</script>

<style lang="scss">
/* CSS VARIABLES - DESIGN SYSTEM SHADCN/UI */
.messenger-flow-builder {
  --background: #ffffff;
  --foreground: #09090b;
  --card: #ffffff;
  --card-foreground: #09090b;
  --primary: #18181b;
  --primary-foreground: #fafafa;
  --secondary: #f4f4f5;
  --secondary-foreground: #18181b;
  --muted: #f4f4f5;
  --muted-foreground: #71717a;
  --accent: #f4f4f5;
  --accent-foreground: #18181b;
  --destructive: #ef4444;
  --destructive-foreground: #fafafa;
  --border: #e4e4e7;
  --input: #e4e4e7;
  --ring: #18181b;
  --radius: 0.5rem;
  --success: #10b981;
  --warning: #f59e0b;
  --info: #3b82f6;
}

/* ESTILOS ESSENCIAIS DO VUE FLOW - INLINE PARA WEWEB */
.vue-flow {
  width: 100%;
  height: 100%;
  position: relative;
  overflow: hidden;
  background: var(--muted);
}

.vue-flow__viewport {
  width: 100%;
  height: 100%;
  position: relative;
  transform-origin: 0 0;
  z-index: 1;
}

.vue-flow__container {
  position: absolute;
  width: 100%;
  height: 100%;
  top: 0;
  left: 0;
}

.vue-flow__pane {
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 1;
  cursor: default;

  &.dragging {
    cursor: grabbing;
  }
}

.vue-flow__transformationpane {
  width: 100%;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
  transform-origin: 0 0;
}

.vue-flow__edges {
  position: absolute;
  width: 100%;
  height: 100%;
  pointer-events: none;
  overflow: visible !important;
}

.vue-flow__edge {
  pointer-events: visibleStroke;
  cursor: pointer;
}

.vue-flow__edge-path {
  stroke: #b1b1b7;
  stroke-width: 2;
  fill: none;
}

.vue-flow__edge.selected .vue-flow__edge-path {
  stroke: #3b82f6;
  stroke-width: 4;
}

/* Custom Edge Delete Button */
.custom-edge-wrapper {
  pointer-events: all;

  &:hover .vue-flow__edge-path {
    stroke: #3b82f6;
    stroke-width: 2.5;
  }
}

.edge-delete-wrapper {
  pointer-events: all;
  overflow: visible;
}

.edge-delete-button {
  width: 20px;
  height: 20px;
  background: var(--destructive);
  border: 2px solid #ffffff;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  transition: all 0.2s ease;
  font-size: 0;
  padding: 0;

  &:hover {
    background: #dc2626;
    transform: scale(1.15);
    box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
  }

  &:active {
    transform: scale(0.95);
  }

  svg {
    width: 12px;
    height: 12px;
    stroke-width: 2;
  }
}

.vue-flow__nodes {
  position: absolute;
  width: 100%;
  height: 100%;
  transform-origin: 0 0;
  pointer-events: none;
}

.vue-flow__node {
  position: absolute;
  user-select: none;
  pointer-events: all;
  cursor: grab;

  &.dragging {
    cursor: grabbing;
  }

  &.selected {
    z-index: 10;
  }
}

/* Selection Rectangle (Box Selection) */
.vue-flow__selection {
  background: rgba(59, 130, 246, 0.08);
  border: 2px solid var(--primary, #3b82f6);
  border-radius: 4px;
}

.vue-flow__selectionpane {
  z-index: 5;
  pointer-events: none !important;
}

/* Hide the multi-node selection rectangle (functionality still works) */
.vue-flow__nodesselection,
.vue-flow__nodesselection-rect {
  display: none !important;
  opacity: 0 !important;
  visibility: hidden !important;
  width: 0 !important;
  height: 0 !important;
  pointer-events: none !important;
}

/* Vue Flow Handles */
.vue-flow__handle {
  position: absolute;
  width: 12px;
  height: 12px;
  background: #555;
  border: 2px solid #fff;
  border-radius: 50%;
  cursor: crosshair;
  z-index: 2;
  
  &-top {
    top: -6px;
    left: 50%;
    transform: translateX(-50%);
  }
  
  &-right {
    right: -6px;
    top: 50%;
    transform: translateY(-50%);
  }
  
  &-bottom {
    bottom: -6px;
    left: 50%;
    transform: translateX(-50%);
  }
  
  &-left {
    left: -6px;
    top: 50%;
    transform: translateY(-50%);
  }
  
  &:hover {
    background: #3b82f6;
  }
}

/* Background Pattern */
.vue-flow__background {
  position: absolute;
  width: 100%;
  height: 100%;
  top: 0;
  left: 0;
  pointer-events: none;
}

.vue-flow__background pattern {
  pointer-events: none;
}

/* Auto-Layout Button */
.auto-layout-button {
  position: absolute;
  bottom: 180px; // Below refresh button with more spacing
  left: 16px;
  z-index: 5;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;  // Match controls container width
  height: 40px; // Match controls container width
  padding: 0;
  background: white;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  cursor: pointer;
  color: var(--foreground);
  transition: all 0.2s;

  &:hover {
    background: var(--accent);
    border-color: var(--primary);
    box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
    transform: translateY(-1px);
  }

  &:active {
    transform: translateY(0) scale(0.98);
  }

  svg {
    flex-shrink: 0;
  }
}

/* Refresh Button - positioned above auto-layout button */
.refresh-button {
  position: absolute;
  bottom: 240px; // Above auto-layout button with clear separation
  left: 16px;
  z-index: 5;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  padding: 0;
  background: white;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  cursor: pointer;
  color: var(--foreground);
  transition: all 0.2s;

  &:hover {
    background: var(--accent);
    border-color: var(--primary);
    box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
    transform: translateY(-1px);

    svg {
      animation: spin 0.6s ease-in-out;
    }
  }

  &:active {
    transform: translateY(0) scale(0.98);
  }

  svg {
    flex-shrink: 0;
  }
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

/* Controls */
.vue-flow__controls {
  position: absolute;
  bottom: 16px;
  left: 16px;
  z-index: 5;
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: var(--radius);
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  padding: 2px;

  button {
    width: 32px;
    height: 32px;
    background: white;
    border: 1px solid #e2e8f0;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: calc(var(--radius) - 4px);
    margin: 2px;
    color: #6b7280;
    
    &:hover {
      background: #f1f5f9;
      color: #111827;
    }
    
    svg {
      width: 16px;
      height: 16px;
    }
  }
}

/* Messenger Flow Builder Container */
.messenger-flow-builder {
  position: relative;
  width: 100%;
  height: 100%;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  overflow: hidden;
}

.messenger-flow {
  width: 100%;
  height: 100%;
  cursor: default;

  /* Panning mode cursor (when space is pressed) */
  &.is-panning {
    cursor: grab !important;

    .vue-flow__pane {
      cursor: grab !important;
    }

    &:active {
      cursor: grabbing !important;

      .vue-flow__pane {
        cursor: grabbing !important;
      }
    }

    // Prevent cursor from changing on nodes when in panning mode
    .messenger-node {
      cursor: grab !important;
    }
  }
}

/* Custom Node Styles - shadcn/ui inspired */
.messenger-node {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: calc(var(--radius) - 2px);
  padding: 0;
  width: 260px;
  font-size: 14px;
  color: var(--card-foreground);
  box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: visible;

  &:not(.start-node) {
    cursor: pointer;
  }

  &:hover {
    border-color: rgba(24, 24, 27, 0.3);
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  }

  &.selected {
    border-color: var(--primary);
    box-shadow: 0 0 0 2px var(--primary), 0 4px 6px -1px rgb(0 0 0 / 0.1);
    transform: translateY(-1px);
  }

  // Nielsen #9: Help Users Recognize Errors - Visual highlight for nodes with validation errors
  &.has-error {
    border-color: var(--destructive);
    animation: errorPulse 2s ease-in-out infinite;

    .node-header {
      border-bottom-color: var(--destructive);
      background: rgba(239, 68, 68, 0.05);
    }
  }

  &.has-warning {
    border-color: var(--warning);
    animation: warningPulse 2s ease-in-out infinite;

    .node-header {
      border-bottom-color: var(--warning);
      background: rgba(245, 158, 11, 0.05);
    }
  }

  .node-header {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px;
    background: rgba(244, 244, 245, 0.5);
    border-bottom: 1px solid var(--border);
    font-weight: 500;
    font-size: 14px;
    color: var(--foreground);
    overflow: hidden;
    border-radius: calc(var(--radius) - 2px) calc(var(--radius) - 2px) 0 0;
  }

  .node-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--muted-foreground);
    flex-shrink: 0;
  }

  .node-title {
    flex: 1;
    text-align: left;
    font-size: 12px;
    font-weight: 500;
    color: var(--foreground);
  }

  .node-validation-icon {
    flex-shrink: 0;
    margin-left: auto;

    &.warning {
      color: #f59e0b;
    }

    &.error {
      color: #ef4444;
    }
  }

  .node-edit, .node-delete, .node-actions {
    background: transparent;
    border: none;
    cursor: pointer;
    width: 20px;
    height: 20px;
    padding: 0;
    opacity: 0;
    transition: all 0.2s;
    border-radius: calc(var(--radius) - 4px);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    color: var(--muted-foreground);
    flex-shrink: 0;

    &:focus-visible {
      outline: 2px solid var(--ring);
      outline-offset: 2px;
    }
  }

  &:hover .node-edit,
  &:hover .node-delete,
  &:hover .node-actions {
    opacity: 1;
  }

  .node-edit, .node-actions {
    svg {
      width: 14px;
      height: 14px;
    }

    &:hover {
      background: var(--accent);
      color: var(--accent-foreground);
    }
  }

  .node-delete {
    font-size: 16px;
    font-weight: 400;
    line-height: 1;
    font-family: system-ui, -apple-system, sans-serif;

    &:hover {
      background: var(--accent);
      color: var(--destructive);
    }
  }

  .node-add-child {
    position: absolute;
    bottom: -12px;
    right: 50%;
    transform: translateX(50%);
    width: 24px;
    height: 24px;
    background: var(--success);
    border: 2px solid #ffffff;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #ffffff;
    opacity: 0;
    transition: all 0.2s ease;
    z-index: 10;

    &:hover {
      background: #059669;
      transform: translateX(50%) scale(1.1);
    }

    &:active {
      transform: translateX(50%) scale(0.95);
    }
  }

  &:hover .node-add-child {
    opacity: 1;
  }

  .node-content {
    padding: 12px;
    font-size: 12px;
    color: var(--muted-foreground);
    line-height: 1.5;
    text-align: left;
    overflow: hidden;
    border-radius: 0 0 calc(var(--radius) - 2px) calc(var(--radius) - 2px);

    p {
      margin: 0;
    }
  }

  &.start-node {
    border-color: var(--primary);

    .node-header {
      background: var(--primary);
      color: var(--primary-foreground);
      border-bottom-color: var(--primary);

      .node-icon {
        color: var(--primary-foreground);
      }

      .node-title {
        color: var(--primary-foreground);
      }
    }

    .node-content {
      color: var(--foreground);
    }
  }

  &.text-node {
    .node-icon {
      color: var(--info); // blue
    }
  }

  &.card-node {
    .node-icon {
      color: #fb923c; // orange
    }
  }

  &.wait-node {
    .node-icon {
      color: var(--warning); // amber
    }
  }

  &.traffic-node {
    min-height: 120px;

    .node-icon {
      color: #8b5cf6; // violet
    }
  }
}

/* Traffic Node Specific */
.traffic-node {
  position: relative;

  .traffic-branches {
    .branch-preview {
      background: rgba(244, 244, 245, 0.3);
      border-left: 2px solid var(--border);
      border-radius: calc(var(--radius) - 4px);
      padding: 8px 12px;
      margin: 8px 0;
      font-size: 12px;
      color: var(--foreground);
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

      &:hover {
        background: var(--accent);
        border-left-color: var(--primary);
        transform: translateX(2px);
      }
    }
  }

}

/* Error Node Specific (for unknown/deprecated node types) */
.error-node {
  min-height: 140px;
  background: #fef2f2;
  border: 2px solid #ef4444;

  .node-header {
    background: #ef4444;
    color: white;

    .node-icon {
      background: rgba(255, 255, 255, 0.2);
    }
  }

  .node-content {
    padding: 12px;
  }

  .error-message {
    p {
      margin: 6px 0;
      font-size: 12px;
      color: #7f1d1d;
      line-height: 1.5;
    }

    code {
      background: #fee2e2;
      padding: 2px 6px;
      border-radius: 4px;
      font-family: 'Monaco', 'Courier New', monospace;
      font-size: 11px;
      color: #991b1b;
      border: 1px solid #fecaca;
    }

    .error-help {
      color: #991b1b;
      font-style: italic;
    }

    .error-action {
      color: #7f1d1d;
      font-weight: 600;
      margin-top: 8px;
    }
  }
}

/* Card preview specific */
.card-preview {
  background: rgba(244, 244, 245, 0.3);
  border-radius: calc(var(--radius) - 4px);
  padding: 12px;
  margin-top: 4px;
  border: 1px solid var(--border);
}

.card-title {
  font-weight: 600;
  font-size: 12px;
  color: var(--foreground);
  margin-bottom: 4px;
}

.card-desc {
  font-size: 12px;
  color: var(--muted-foreground);
  line-height: 1.4;
}

.card-image-placeholder {
  background: rgba(244, 244, 245, 0.5);
  border: 1px dashed var(--border);
  border-radius: calc(var(--radius) - 4px);
  padding: 16px;
  text-align: center;
  color: var(--muted-foreground);
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.card-url {
  font-size: 12px;
  color: var(--muted-foreground);
  margin-top: 6px;
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Button preview */
.node-buttons {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid var(--border);

  .button-preview {
    background: var(--secondary);
    border: 1px solid var(--border);
    border-radius: calc(var(--radius) - 4px);
    padding: 6px 10px;
    margin: 2px 0;
    font-size: 12px;
    color: #1e40af;
  }
}

/* Components Dock - shadcn/ui inspired */
.components-dock {
  position: absolute;
  left: 16px;
  top: 16px;
  background: var(--card);
  border-radius: var(--radius);
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  padding: 12px;
  width: 190px;
  z-index: 5;
  border: 1px solid var(--border);
  transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: visible;

  .dock-toggle {
    position: absolute;
    top: 16px;
    right: -14px;
    width: 28px;
    height: 28px;
    border: none;
    background: var(--warning);
    color: #18181b;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 10;
    flex-shrink: 0;
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);

    svg {
      width: 16px;
      height: 16px;
      transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
    }

    &:hover {
      transform: scale(1.08);
    }

    &:active {
      transform: scale(0.92);
      box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
    }

    &:focus-visible {
      outline: 2px solid #F4C430;
      outline-offset: 2px;
    }
  }

  .dock-content {
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    opacity: 1;
    visibility: visible;
  }

  &.collapsed {
    width: 72px;
    min-width: 72px;
    padding: 12px;

    .dock-toggle {
      position: absolute;
      top: 16px;
      right: -14px;
      width: 28px;
      height: 28px;
      margin: 0;

      &:hover {
        transform: scale(1.08);
      }

      &:active {
        transform: scale(0.92);
      }
    }

    .dock-content {
      opacity: 1;
      visibility: visible;
    }

    .dock-items {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .dock-item {
      flex-direction: column;
      padding: 12px;
      min-height: auto;
      justify-content: center;
      align-items: center;
      gap: 0;

      span {
        display: none;
      }

      svg {
        margin: 0;
        width: 24px;
        height: 24px;
      }
    }
  }


  .dock-items {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .dock-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 12px;
    border-radius: calc(var(--radius) - 2px);
    cursor: pointer;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    font-size: 14px;
    font-weight: 500;
    color: var(--foreground);
    border: 1px solid transparent;
    background: transparent;

    &:hover {
      background: var(--accent);
      color: var(--accent-foreground);
      border-color: var(--border);
    }

    &:active {
      scale: 0.98;
    }

    svg {
      color: var(--muted-foreground);
      flex-shrink: 0;
    }

    &:hover svg {
      color: var(--accent-foreground);
    }

    span {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }

  // Disabled item for protected nodes (like Start)
  .disabled-item {
    cursor: not-allowed;
    opacity: 0.6;
    color: var(--muted-foreground);

    &:hover {
      background: transparent;
      border-color: transparent;
      scale: 1;
    }

    svg {
      color: var(--destructive);
    }
  }
}

/* Empty State - n8n inspired */
.empty-state {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  z-index: 1;

  .empty-state-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 16px;
    padding: 32px;
  }

  .empty-state-icon {
    width: 120px;
    height: 120px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 4px dashed var(--border);
    border-radius: var(--radius);
    background: var(--card);
    color: var(--muted-foreground);
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    padding: 0;

    svg {
      opacity: 0.5;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    &:hover {
      border-color: var(--primary);
      background: rgba(24, 24, 27, 0.02);
      transform: scale(1.05);

      svg {
        opacity: 1;
        color: var(--primary);
      }
    }

    &:active {
      transform: scale(0.95);
    }
  }

  .empty-state-title {
    font-size: 18px;
    font-weight: 600;
    color: var(--foreground);
    margin: 0;
  }

  .empty-state-description {
    font-size: 14px;
    color: var(--muted-foreground);
    margin: 0;
    max-width: 300px;
  }
}

/* Toolbar - shadcn/ui inspired */
.toolbar {
  position: absolute;
  top: 16px;
  right: 16px;
  display: flex;
  gap: 8px;
  z-index: 5;
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 4px;
  box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);

  .toolbar-btn {
    width: 36px;
    height: 36px;
    border: none;
    background: transparent;
    border-radius: calc(var(--radius) - 2px);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    color: var(--muted-foreground);
    position: relative;

    &:hover {
      background: var(--accent);
      color: var(--accent-foreground);
    }

    &:active {
      scale: 0.95;
    }

    &:focus-visible {
      outline: 2px solid var(--ring);
      outline-offset: 2px;
    }

    &.primary {
      background: var(--primary);
      color: var(--primary-foreground);

      &:hover {
        background: rgba(24, 24, 27, 0.9);
      }
    }

    &.destructive {
      &:hover {
        background: var(--destructive);
        color: var(--destructive-foreground);
      }
    }
  }
}

/* Edit Sidebar - shadcn/ui inspired */
.edit-sidebar {
  position: absolute;
  right: 16px;
  top: 60px;
  width: 340px;
  background: var(--card);
  border-radius: var(--radius);
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  border: 1px solid var(--border);
  z-index: 10;
  max-height: calc(100% - 80px);
  overflow-y: auto;

  .sidebar-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 20px;
    border-bottom: 1px solid var(--border);

    h3 {
      font-size: 16px;
      font-weight: 600;
      margin: 0;
      color: var(--foreground);
    }

    .close-btn {
      width: 32px;
      height: 32px;
      border: none;
      background: transparent;
      font-size: 20px;
      cursor: pointer;
      color: var(--muted-foreground);
      border-radius: calc(var(--radius) - 2px);
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      display: flex;
      align-items: center;
      justify-content: center;

      &:hover {
        background: var(--accent);
        color: var(--accent-foreground);
      }

      &:active {
        scale: 0.95;
      }
    }
  }

  .sidebar-content {
    padding: 20px;
  }

  .form-group {
    margin-bottom: 20px;

    label {
      display: block;
      margin-bottom: 8px;
      font-weight: 500;
      color: var(--foreground);
      font-size: 14px;
      letter-spacing: -0.01em;
    }

    input:not([type="file"]),
    textarea,
    select {
      width: 100%;
      padding: 12px 12px;
      border: 1px solid var(--input);
      border-radius: calc(var(--radius) - 2px);
      font-size: 14px;
      background: var(--background);
      color: var(--foreground);
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

      &::placeholder {
        color: var(--muted-foreground);
      }

      &:hover {
        border-color: var(--ring);
      }

      &:focus {
        outline: none;
        border-color: var(--ring);
        box-shadow: 0 0 0 3px rgba(24, 24, 27, 0.05);
      }

      &:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }
    }

    textarea {
      resize: vertical;
      min-height: 100px;
      font-family: inherit;
      line-height: 1.5;
    }

    select {
      cursor: pointer;
      padding-right: 32px;
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%2371717a' d='M6 9L1 4h10z'/%3E%3C/svg%3E");
      background-repeat: no-repeat;
      background-position: right 12px center;
      appearance: none;
    }
  }

  .sidebar-actions {
    display: flex;
    gap: 12px;
    margin-top: 24px;
    padding-top: 20px;
    border-top: 1px solid var(--border);

    button {
      flex: 1;
      height: 40px;
      padding: 0 16px;
      border: none;
      border-radius: calc(var(--radius) - 2px);
      font-weight: 500;
      cursor: pointer;
      font-size: 14px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      display: inline-flex;
      align-items: center;
      justify-content: center;

      &:active {
        scale: 0.98;
      }

      &:focus-visible {
        outline: 2px solid var(--ring);
        outline-offset: 2px;
      }
    }

    .save-btn {
      background: var(--primary);
      color: var(--primary-foreground);

      &:hover {
        background: rgba(24, 24, 27, 0.9);
      }
    }

    .cancel-btn {
      background: var(--secondary);
      color: var(--secondary-foreground);

      &:hover {
        background: rgba(244, 244, 245, 0.8);
      }
    }
  }

  .buttons-editor,
  .traffic-editor {
    border: 1px solid var(--border);
    border-radius: calc(var(--radius) - 2px);
    padding: 16px;
    background: var(--muted);
  }

  .button-editor,
  .branch-editor {
    margin-bottom: 12px;
    padding: 12px;
    background: var(--card);
    border-radius: calc(var(--radius) - 4px);
    border: 1px solid var(--border);

    &:last-of-type {
      margin-bottom: 0;
    }
  }

  .button-row,
  .branch-row {
    position: relative;
    padding-right: 40px;

    input, select {
      width: 100%;
      height: 36px;
      padding: 0 10px;
      border: 1px solid var(--input);
      border-radius: calc(var(--radius) - 4px);
      font-size: 14px;
      background: var(--background);
      color: var(--foreground);
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      margin-bottom: 8px;

      &::placeholder {
        color: var(--muted-foreground);
      }

      &:hover {
        border-color: var(--ring);
      }

      &:focus {
        outline: none;
        border-color: var(--ring);
        box-shadow: 0 0 0 2px rgba(24, 24, 27, 0.05);
      }
    }

    select {
      cursor: pointer;
      padding-right: 32px;
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='10' viewBox='0 0 10 10'%3E%3Cpath fill='%2371717a' d='M5 7L1 3h8z'/%3E%3C/svg%3E");
      background-repeat: no-repeat;
      background-position: right 12px center;
      appearance: none;
    }

    .remove-btn {
      position: absolute;
      top: 0;
      right: 0;
      width: 32px;
      height: 32px;
      background: var(--background);
      color: var(--destructive);
      border: 1px solid var(--border);
      border-radius: calc(var(--radius) - 4px);
      cursor: pointer;
      font-size: 18px;
      font-weight: 400;
      line-height: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

      &:hover {
        background: var(--destructive);
        color: var(--destructive-foreground);
        border-color: var(--destructive);
      }

      &:active {
        scale: 0.95;
      }
    }
  }

  .button-editor {
    input.button-input {
      width: 100%;
      height: 36px;
      padding: 0 10px;
      border: 1px solid var(--input);
      border-radius: calc(var(--radius) - 4px);
      font-size: 14px;
      background: var(--background);
      color: var(--foreground);
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      margin-bottom: 8px;

      &::placeholder {
        color: var(--muted-foreground);
      }

      &:hover {
        border-color: var(--ring);
      }

      &:focus {
        outline: none;
        border-color: var(--ring);
        box-shadow: 0 0 0 2px rgba(24, 24, 27, 0.05);
      }

      &:last-child {
        margin-bottom: 0;
      }
    }
  }

  .add-button {
    height: 36px;
    background: var(--primary);
    color: var(--primary-foreground);
    border: none;
    border-radius: calc(var(--radius) - 2px);
    padding: 0 14px;
    cursor: pointer;
    font-size: 12px;
    font-weight: 500;
    width: 100%;
    margin-top: 12px;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;

    &:hover {
      background: rgba(24, 24, 27, 0.9);
    }

    &:active {
      scale: 0.98;
    }

    &:focus-visible {
      outline: 2px solid var(--ring);
      outline-offset: 2px;
    }
  }

  .traffic-actions {
    display: flex;
    gap: 8px;
    margin-top: 12px;

    .add-button {
      margin-top: 0;
      flex: 1;
    }

    .distribute-button {
      flex: 1;
      height: 36px;
      background: var(--secondary);
      color: var(--secondary-foreground);
      border: 1px solid var(--border);
      border-radius: calc(var(--radius) - 2px);
      padding: 0 14px;
      cursor: pointer;
      font-size: 12px;
      font-weight: 500;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;

      &:hover:not(:disabled) {
        background: var(--accent);
        border-color: var(--primary);
      }

      &:active:not(:disabled) {
        scale: 0.98;
      }

      &:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      &:focus-visible {
        outline: 2px solid var(--ring);
        outline-offset: 2px;
      }
    }
  }

  .percentage-total {
    margin-top: 16px;
    padding: 12px 12px;
    background: var(--card);
    border-radius: calc(var(--radius) - 4px);
    border: 1px solid var(--border);
    font-size: 12px;
    text-align: center;
    font-weight: 500;
    color: var(--foreground);

    .warning {
      display: inline-block;
      margin-left: 8px;
      color: var(--destructive);
      font-weight: 600;
    }
  }

  .file-input {
    width: 100%;
    padding: 12px 12px;
    border: 1px dashed var(--input);
    border-radius: calc(var(--radius) - 2px);
    background: var(--muted);
    cursor: pointer;
    font-size: 14px;
    color: var(--foreground);
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

    &:hover {
      border-color: var(--ring);
      background: rgba(244, 244, 245, 0.8);
    }

    &::file-selector-button {
      padding: 6px 12px;
      border: none;
      background: var(--primary);
      color: var(--primary-foreground);
      border-radius: calc(var(--radius) - 4px);
      cursor: pointer;
      font-size: 12px;
      font-weight: 500;
      margin-right: 12px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

      &:hover {
        background: rgba(24, 24, 27, 0.9);
      }
    }
  }

  .image-url-input {
    margin-top: 8px;
  }

  .image-preview {
    margin-top: 12px;
    padding: 12px;
    background: var(--muted);
    border: 1px solid var(--border);
    border-radius: calc(var(--radius) - 2px);
    text-align: center;

    img {
      max-width: 100%;
      max-height: 120px;
      border-radius: calc(var(--radius) - 4px);
      object-fit: contain;
    }
  }

  .percentage-sign {
    color: var(--muted-foreground);
    font-size: 12px;
    font-weight: 500;
  }

  // Validation badges
  .success-badge {
    display: inline-block;
    margin-left: 8px;
    color: #10b981;
    font-weight: 600;
  }

  .warning-badge {
    display: inline-block;
    margin-left: 8px;
    color: var(--destructive);
    font-weight: 600;
  }

  // Form validation styles
  .has-error {
    input, textarea, select {
      border-color: var(--destructive) !important;
    }
  }

  .input-error {
    border-color: var(--destructive) !important;
    &:focus {
      outline-color: var(--destructive);
      border-color: var(--destructive);
    }
  }

  .field-error {
    display: block;
    margin-top: 6px;
    font-size: 12px;
    color: var(--destructive);
    font-weight: 500;
  }

  // Percentage total validation
  .percentage-total.valid {
    border-color: #10b981;
    background: rgba(16, 185, 129, 0.05);
  }

  .percentage-total.invalid {
    border-color: var(--destructive);
    background: rgba(239, 68, 68, 0.05);
  }
}

/* Toast Notifications - shadcn/ui inspired */
.toast-container {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-width: 420px;
  pointer-events: none;

  .toast {
    pointer-events: all;
    display: flex;
    align-items: flex-start;
    gap: 12px;
    padding: 16px;
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
    min-width: 300px;
    max-width: 420px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

    &.toast-success {
      border-left: 4px solid #10b981;
      .toast-icon {
        color: #10b981;
      }
    }

    &.toast-error {
      border-left: 4px solid var(--destructive);
      .toast-icon {
        color: var(--destructive);
      }
    }

    &.toast-warning {
      border-left: 4px solid #f59e0b;
      .toast-icon {
        color: #f59e0b;
      }
    }

    &.toast-info {
      border-left: 4px solid #3b82f6;
      .toast-icon {
        color: #3b82f6;
      }
    }

    .toast-icon {
      flex-shrink: 0;
      margin-top: 2px;
    }

    .toast-content {
      flex: 1;
      min-width: 0;

      .toast-title {
        font-weight: 600;
        font-size: 14px;
        color: var(--foreground);
        margin: 0 0 4px 0;
      }

      .toast-message {
        font-size: 13px;
        color: var(--muted-foreground);
        margin: 0;
        line-height: 1.4;
      }
    }

    .toast-close {
      flex-shrink: 0;
      background: transparent;
      border: none;
      color: var(--muted-foreground);
      cursor: pointer;
      font-size: 20px;
      line-height: 1;
      padding: 0;
      width: 20px;
      height: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 4px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

      &:hover {
        background: var(--accent);
        color: var(--accent-foreground);
      }
    }
  }
}

/* Toast Animations */
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100px);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100px) scale(0.95);
}

.toast-move {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Custom Dialog Styles (shadcn/ui inspired) */
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100000;
  animation: dialogOverlayShow 0.15s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes dialogOverlayShow {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.dialog {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  width: 90%;
  max-width: 500px;
  max-height: 85vh;
  overflow: auto;
  animation: dialogContentShow 0.15s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes dialogContentShow {
  from {
    opacity: 0;
    transform: translate(0, -4px) scale(0.96);
  }
  to {
    opacity: 1;
    transform: translate(0, 0) scale(1);
  }
}

.dialog-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px 24px 16px 24px;
  border-bottom: 1px solid var(--border);
}

.dialog-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--foreground);
  line-height: 1;
}

.dialog-icon {
  flex-shrink: 0;
}

.dialog-icon.warning {
  color: #f59e0b;
}

.dialog-icon.info {
  color: var(--primary);
}

.dialog-body {
  padding: 20px 24px;
}

.dialog-message {
  margin: 0 0 12px 0;
  font-size: 14px;
  line-height: 1.5;
  color: var(--muted-foreground);
}

.dialog-message:last-child {
  margin-bottom: 0;
}

.dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 16px 24px 20px 24px;
  border-top: 1px solid var(--border);
}

.dialog-btn {
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  border-radius: calc(var(--radius) - 2px);
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  white-space: nowrap;
}

.dialog-btn:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.dialog-btn-cancel {
  background: transparent;
  border-color: var(--border);
  color: var(--foreground);
}

.dialog-btn-cancel:hover {
  background: var(--accent);
  border-color: var(--border);
}

.dialog-btn-cancel:active {
  transform: scale(0.98);
}

.dialog-btn-confirm {
  background: var(--primary);
  color: var(--primary-foreground);
  border-color: var(--primary);
}

.dialog-btn-confirm:hover {
  opacity: 0.9;
}

.dialog-btn-confirm:active {
  transform: scale(0.98);
}

/* Validation Tooltip Styles */
.validation-tooltip {
  position: fixed;
  transform: translate(-50%, -100%);
  z-index: 100001;
  pointer-events: none;
  animation: tooltipShow 0.15s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes tooltipShow {
  from {
    opacity: 0;
    transform: translate(-50%, calc(-100% + 4px));
  }
  to {
    opacity: 1;
    transform: translate(-50%, -100%);
  }
}

.tooltip-issue {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: calc(var(--radius) - 2px);
  padding: 8px 12px;
  font-size: 13px;
  line-height: 1.4;
  color: var(--foreground);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  margin-bottom: 4px;
  white-space: nowrap;
  max-width: 300px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tooltip-issue:last-child {
  margin-bottom: 0;
}

.tooltip-issue.error {
  border-left: 3px solid #ef4444;
  background: rgba(239, 68, 68, 0.05);
}

.tooltip-issue.warning {
  border-left: 3px solid #f59e0b;
  background: rgba(245, 158, 11, 0.05);
}

/* Helper Lines Canvas Styles */
.helper-lines-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 10;
  pointer-events: none;
}

/* Custom Connection Line Animation */
.vue-flow__connection-path.animated {
  stroke-dasharray: 5;
  stroke-dashoffset: 0;
  animation: connectionLineDash 0.5s linear infinite;
}

/* Animated edges after connection */
.vue-flow__edge.animated path.vue-flow__edge-path {
  stroke-dasharray: 5 !important;
  stroke-dashoffset: 0;
  animation: connectionLineDash 0.5s linear infinite;
}

@keyframes connectionLineDash {
  from {
    stroke-dashoffset: 0;
  }
  to {
    stroke-dashoffset: -10;
  }
}

/* ============================================================================ */
/* CONTEXT MENUS (reuse dock styles) */
/* ============================================================================ */

// Unified overlay for all context menus
.child-node-menu-overlay,
.actions-menu-overlay {
  position: fixed;
  inset: 0;
  background: transparent;
  pointer-events: auto;
}

.child-node-menu-overlay {
  z-index: 10000;
}

.actions-menu-overlay {
  z-index: 10001;
}

// Child node menu inherits ALL styles from .components-dock
// Only override positioning and animation
.child-node-menu {
  // Override dock's absolute positioning to fixed
  position: fixed !important;

  // Entry animation
  animation: slideInFromRight 0.2s ease-out;

  // Max height for scrolling (dock doesn't have this)
  max-height: 400px;
  overflow-y: auto;

  // Always show content (dock has toggle button, menu doesn't)
  .dock-content {
    opacity: 1 !important;
    visibility: visible !important;
  }
}

// Actions menu - Simple menu that reuses dock styles
.actions-menu {
  position: fixed !important;
  animation: slideInFromRight 0.2s ease-out;
  min-width: 160px;

  .dock-content {
    opacity: 1 !important;
    visibility: visible !important;
  }
}

@keyframes slideInFromRight {
  from {
    opacity: 0;
    transform: translateX(-10px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

/* Navigation Hint */
.navigation-hint {
  position: absolute;
  bottom: 80px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--card);
  padding: 12px 20px;
  border-radius: var(--radius);
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  font-size: 14px;
  z-index: 5;
  pointer-events: none;
  animation: fadeIn 0.3s ease-in;

  kbd {
    background: var(--muted);
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: bold;
    font-family: monospace;
    border: 1px solid var(--border);
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
}

/* ============================================================================
   ACCESSIBILITY: FOCUS INDICATORS (WCAG 2.1 AA Compliance)
   ============================================================================ */

/* Global focus-visible for all interactive elements */
button:focus-visible,
input:focus-visible,
select:focus-visible,
textarea:focus-visible,
a:focus-visible,
[tabindex]:focus-visible,
.dock-item:focus-visible,
.messenger-node:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
  transition: outline-offset 0.2s ease;
}

/* Remove outline on mouse focus (only show on keyboard navigation) */
button:focus:not(:focus-visible),
input:focus:not(:focus-visible),
select:focus:not(:focus-visible),
textarea:focus:not(:focus-visible),
a:focus:not(:focus-visible),
[tabindex]:focus:not(:focus-visible) {
  outline: none;
}

/* Enhanced focus for primary actions */
.add-button:focus-visible,
.save-button:focus-visible,
.distribute-button:focus-visible {
  outline: 3px solid var(--primary);
  outline-offset: 3px;
}

/* Destructive actions get red focus */
.remove-btn:focus-visible,
.delete-button:focus-visible,
.toolbar-btn:focus-visible {
  outline: 2px solid var(--destructive);
  outline-offset: 2px;
}

/* ============================================================================
   ANIMATIONS: Error & Warning Pulse (Nielsen #9 - Error Recognition)
   ============================================================================ */

@keyframes errorPulse {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(239, 68, 68, 0);
  }
}

@keyframes warningPulse {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(245, 158, 11, 0.4);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(245, 158, 11, 0);
  }
}

// Empty state dentro do form de edição (sobrescreve o position: absolute do canvas)
.edit-sidebar .edit-form .empty-state {
  position: relative !important;
  background: rgba(250, 204, 21, 0.05);
  border: 1px solid rgba(250, 204, 21, 0.2);
  border-radius: var(--radius);
  padding: 16px;
  margin: 0;
  text-align: center;
  pointer-events: all;
  display: block;
  top: auto;
  left: auto;
  right: auto;
  bottom: auto;
  z-index: auto;
}

.edit-sidebar .edit-form {
  .empty-message {
    font-size: 14px;
    color: var(--warning);
    margin: 0 0 8px 0;
    font-weight: 600;
  }

  .empty-hint {
    font-size: 13px;
    color: var(--muted-foreground);
    margin: 0;
    line-height: 1.5;
  }
}</style>
