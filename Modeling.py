
from bs4 import BeautifulSoup
import numpy as np
import sys
import os
from sklearn.decomposition import PCA
class Texturemodel():
    def __init__(self, path):
        self.model_path = path
        self.read_model()
        self.read_force_speed(self.soup)
    def read_model(self):
        with open(self.model_path, 'r') as f:
            data = f.read()
        self.soup = BeautifulSoup(data, 'xml')
        tris = self.soup.find_all('tri')
        self.tris_index = []
        for tri in tris:
            idx_values = [value.text for value in tri.find_all('value')]
            self.tris_index.append(idx_values)
    def read_force_speed(self, soup):
        speed = soup.find('speedList')
        self.speeds = [value.text for value in speed.find_all('value')]
        force = soup.find('forceList')
        self.forces = [value.text for value in force.find_all('value')]
        ARl = soup.find_all('ARlsf')
        self.AR_list = []
        for art in ARl:
            #print(art)
            ast = [float(value.text) for value in art.find_all('value')]
            self.AR_list.append(ast)
        #return speeds, forces, AR_list
    
    def get_back(self, c_f, c_s ):
        assert c_f <2.0, "out of range, make sure between 0-2.0"
        assert c_s <200, "out of range, make sure between 0-200"
        for tri_idx_l in self.tris_index:
            tri_idx = [int(i) - 1 for i in tri_idx_l] # 1, n
            p1 = [float(self.forces[tri_idx[0]]), float(self.speeds[tri_idx[0]])]
            p2 = [float(self.forces[tri_idx[1]]), float(self.speeds[tri_idx[1]])]
            p3 = [float(self.forces[tri_idx[2]]), float(self.speeds[tri_idx[2]])]
            point = [float(c_f),float(c_s)]
            triangle = [p1, p2, p3]
            
            if self.is_inside_triangle(point, triangle):
                v1 = np.array(self.AR_list[tri_idx[0]])
                v2 = np.array(self.AR_list[tri_idx[1]])
                v3 = np.array(self.AR_list[tri_idx[2]])
                #import pdb; pdb.set_trace()
                ar_lsp = self.barycentric_interpolation(point, triangle, [v1,v2,v3])
                return ar_lsp

    def is_inside_triangle(self, point, triangle):
        x, y = point
        x1, y1 = triangle[0]
        x2, y2 = triangle[1]
        x3, y3 = triangle[2]
        #print(triangle)
        denominator = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
        alpha = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denominator
        beta = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denominator
        gamma = 1 - alpha - beta

        # Check if the point is inside the triangle
        if 0 <= alpha <= 1 and 0 <= beta <= 1 and 0 <= gamma <= 1:
            return True
        else:
            return False

    def barycentric_interpolation(self, point, triangle, values):
        """
        Perform barycentric interpolation based on a 2D triangle.

        Args:
            point: A tuple (x, y) representing the coordinates of the point to interpolate.
            triangle: A list of three tuples representing the coordinates of the vertices of the triangle.
            values: A list of three values corresponding to the values at the vertices of the triangle.

        Returns:
            The interpolated value at the point.
        """
        # Calculate the barycentric coordinates of the point with respect to the triangle
        x, y = point
        x1, y1 = triangle[0]
        x2, y2 = triangle[1]
        x3, y3 = triangle[2]
        denominator = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
        alpha = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denominator
        beta = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denominator
        gamma = 1 - alpha - beta

        # Interpolate the value at the point
        interpolated_value = alpha * values[0] + beta * values[1] + gamma * values[2]
        return interpolated_value



class Morphable_Model(Texturemodel):
    def __init__(self, root_path):
        self.textures = []
        for xmlfi in os.listdir(root_path):
            texture = Texturemodel(os.path.join(root_path, xmlfi))
            self.textures.append(texture)
    #@staticmethod
    def get_ar_features(self, c_f, c_s, alpha, target= None):
        self.ar_feature= []
        for texture in self.textures:
            self.ar_feature.append(texture.get_back(float(c_f), float(c_s))[:14]) # align to the same dimension 14

        ar_feat = np.stack(self.ar_feature, axis=0)
        pca, eigen_values, eigenvectors = self.pcaf(ar_feat)

        if target is not None:
            target = np.array(target)
            target = target.reshape(1, -1)
            target_compressed = pca.transform(target)
            target_compressed[0] = target_compressed[0] * alpha
            x_new_reconstructed = pca.inverse_transform(target_compressed)

        else:
            x_new_reconstructed = pca.inverse_transform(pca.mean_ + alpha * np.dot(eigenvectors, np.sqrt(eigen_values)))
        #import pdb;pdb.set_trace()
        return x_new_reconstructed
    #@staticmethod
    def pcaf(self, ar_features):
        #ar_features = np.array(ar_features)
        pca = PCA(n_components=5)
        x_new = pca.fit_transform(ar_features) # 100x8
        eigen_values = pca.explained_variance_
        eigenvectors = pca.components_
        return pca, eigen_values, eigenvectors



if __name__ == '__main__':
    #path = input("Please enter the texture xml path:")
    path = 'Models_ABSdPlastic.xml'
    print("Using ", path.split('/')[-1], "as an example")
    targetmodel = Texturemodel(path) 
    root = './Models/Models10000Hz/XML'
    morph_model = Morphable_Model(root)
            
    c_f = 1.0
    c_s = 100.0    
    alpha = 0.5
    targetar = targetmodel.get_back(float(c_f), float(c_s))[:14] # align to the same dimension 14
    rendered_arfeature = morph_model.get_ar_features(float(c_f), float(c_s), alpha, target=targetar)
    #render_arfeature = a.get_ar_features(c_f, c_s, 1, target=targetar)
        
    print("Force {} Netwon, Speed {} mm/s 's AR feature:\n".format(c_f, c_s))
    print("morphaded AR feature:\n", rendered_arfeature)
    print("original AR feature:\n", targetar)