__author__ = "Priyabrata Biswal"
#################################################################################
# tool = LOD Checker															#
# author = "Priyabrata Biswal"													#
# last_updated = "2019_01_27													#
#																				#
# doc = "see_below"																#
# Checks lower lod's vertex positions against highest lod.						#
# If there are mis-match the tool selects the vertices on lower lods mesh.		#
# 																				#
# 																				#
#################################################################################
import pymxs
from pymxs import runtime as rt
from PySide import QtGui, QtCore
import MaxPlus
import math
name_filter = "_LOD"
class _GCProtector(object):
	widgets = []
app = QtGui.QApplication.instance()
if not app:
	app = QtGui.QApplication([])

class LevelOfDetailChecker(QtGui.QWidget):
	def __init__(self, parent=None):
		super(LevelOfDetailChecker,self).__init__(parent)
		self.setWindowTitle("LOD Checker")
		main_layout = QtGui.QVBoxLayout()
		# Class Variables
		self.tolerance = 0.1
		# Help Labels
		label = QtGui.QLabel("### LOD Checker v1.0 ###\nAuthor: Priyabrata Biswal")
		label.setAlignment(QtCore.Qt.AlignCenter)
		label.setStyleSheet("font-weight: bold; color: yellow");
		label_1 = QtGui.QLabel("Select highest LOD and Check to select problem vertices in lower LODs.")
		label_2 = QtGui.QLabel("\nSteps : \n1. Select Highest LOD Mesh (Name Format : AnyMeshName_LOD0\n2. Press Check Button\n3. Once done, lower lods will have problem vertices selected.")
		main_layout.addWidget(label)
		main_layout.addWidget(label_1)
		main_layout.addWidget(label_2)
		# Tolerance
		lt_tolerance = QtGui.QHBoxLayout()
		lbl_tolerance = QtGui.QLabel("Tolerance : ")
		self.spn_tolerance = QtGui.QDoubleSpinBox()
		self.spn_tolerance.setValue(0.1)
		self.spn_tolerance.setSingleStep(0.1)
		self.spn_tolerance.setSuffix(" cm")
		self.spn_tolerance.valueChanged.connect(self.update_values)
		lt_tolerance.addWidget(lbl_tolerance)
		lt_tolerance.addWidget(self.spn_tolerance)
		main_layout.addLayout(lt_tolerance)
		# Progress Bar
		self.pbar = QtGui.QProgressBar()
		self.pbar.setValue(0)
		self.pbar.setTextVisible(False)
		main_layout.addWidget(self.pbar)
		# Check
		self.btn_check = QtGui.QPushButton("Check")
		self.btn_check.clicked.connect(self.process_selection)
		main_layout.addWidget(self.btn_check)
		self.setLayout(main_layout)
		self.update_values()

	def update_values(self):
		self.tolerance = self.spn_tolerance.value()
		self.pbar.setValue(0)

	def get_all_lod(self,node):
		asset_name = node.Name.split(name_filter)[0]
		result = []
		for a in MaxPlus.Core.GetRootNode().Children:
			if asset_name + name_filter in a.Name:
				result.append(a)
		return result


	def get_mesh_from_node(self, node):
		node.Convert(MaxPlus.ClassIds.TriMeshGeometry)
		object_state = node.EvalWorldState()
		obj_original = object_state.Getobj()
		tri_obj = MaxPlus.TriObject._CastFrom(obj_original)
		return tri_obj.GetMesh()


	def distance(self, x, y):
		x = (x.X,x.Y,x.Z)
		y = (y.X,y.Y,y.Z)
		return math.sqrt(sum([(a - b) ** 2 for a, b in zip(x, y)]))

	# Add a Select Modifier if problem found
	def compare_mesh_vert_pos(self, src, target):
		src_mesh = self.get_mesh_from_node(src)
		target_mesh = self.get_mesh_from_node(target)
		ba_bad_verts = MaxPlus.BitArray()
		ba_bad_verts.SetSize(target_mesh.GetNumVertices())
		print "{0} with {1}".format(target.Name, src.Name)
		for t in xrange(target_mesh.GetNumVertices()):
			distances = []
			for s in xrange(src_mesh.GetNumVertices()):
				_distance = self.distance(target_mesh.GetVertex(t), src_mesh.GetVertex(s))
				# Check if Distance is lower than Tolerance
				distances.append(_distance < self.tolerance)
			# index of non-existent item in list returns ValueError
			try:
				idx = distances.index(True)
			except ValueError: # Pos Mismatch / Bad Verts
				ba_bad_verts.Set(t, True)
		return ba_bad_verts

	def select_vertices(self, node, ba_verts):
		# Select Verts on Mesh
		mesh = self.get_mesh_from_node(node)
		mesh.SetVertSel(ba_verts)

	def validate_vertex_pos(self, source_node, target_nodes):
		error_string = ""
		self.pbar.setMaximum(len(target_nodes))
		for i,target in enumerate(target_nodes):
    			bad_verts = self.compare_mesh_vert_pos(source_node, target)
			if bad_verts.GetSize() < 1:
				continue
			error_string += ("{0}\n".format(target.Name))
			self.select_vertices(target, bad_verts)
			self.pbar.setValue(i+1)
		if len(error_string) > 0:
			QtGui.QMessageBox.about(self,
			"LOD Vertex Mismatch",
			"The following meshes have issues.\n{0}".format(error_string))

	def process_selection(self):
		self.pbar.setValue(0)
		sel = MaxPlus.SelectionManager.GetNodes()
		if len(sel) != 1:
			QtGui.QMessageBox.about(self,
			"Selection Error",
			"Please select ONLY the highest LOD mesh. Make sure there is no modifiers.")
			return
		sel = sel[0]
		all_lods = self.get_all_lod(sel)
		if all_lods < 1:
			QtGui.QMessageBox.about(self,
			"LOD Error",
			"Not enough LODs found for {0}".format(sel.Name))
			return 0
		self.validate_vertex_pos(all_lods[0], all_lods[1:])


def main():
	#MaxPlus.FileManager.Reset(True)
	tool = LevelOfDetailChecker(parent=MaxPlus.GetQMaxWindow())
	_GCProtector.widgets.append(tool)
	tool.show()


if __name__ == '__main__':
	main()