
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
        self.max_s, self.min_s = 200, 0 # mm/s
        self.max_f, self.min_f = 2.4, 0 # Newton
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
        self.speeds = [float(value.text) for value in speed.find_all('value')]
        force = soup.find('forceList')
        self.forces = [float(value.text) for value in force.find_all('value')]
        ARl = soup.find_all('ARlsf')
        self.AR_list = []
        for art in ARl:
            #print(art)
            ast = [float(value.text) for value in art.find_all('value')]
            self.AR_list.append(ast)
        #return speeds, forces, AR_list
    def change_value(self, soup, speeds, forces, AR_generated, AR_coefs, save_path):
        speedlist = soup.find('speedList')
        forceslist = soup.find('forceList')
        for c, value in enumerate(speedlist.find_all('value')):
            value.string = str(speeds[c])
        for c, value in enumerate(forceslist.find_all('value')):
            value.string = str(forces[c])

        ARl = soup.find_all('ARlsf')
        for c, art in enumerate(ARl):
            AR_g = AR_generated[c]
            #print("c:", c, art)
            for d, value in enumerate(art.find_all('value')):
                value.string = str(AR_g[d])

        ARc = soup.find_all('ARcoeff')
        for c, Arc_sp in enumerate(ARc):
            ARc_f = AR_coefs[c]
            for d, value in enumerate(Arc_sp.find_all('value')):
                value.string = str(ARc_f[d])

        #change speed Mod value as well
        for c, speed_mod_element in enumerate(soup.find_all('speedMod')):
            speed_mod_element.string = str(speeds[c])
        #change force Mod value as well
        for c, force_mod_element in enumerate(soup.find_all('forceMod')):
            force_mod_element.string = str(forces[c])
            #str(float(value.text) * 1000) 
        for maxSpeed in soup.find_all("maxSpeed"):
            maxSpeed.string = str(max(speeds)) 
        for maxForce in soup.find_all("maxForce"):
            maxForce.string = str(max(forces))
        with open(save_path, "w") as file:
            file.write(str(soup))
        print("Saved to: ", save_path) 
                 
    def get_back(self, c_f, c_s ):
        #assert c_f <2.0, "out of range, make sure between 0-2.0"
        #assert c_s <200, "out of range, make sure between 0-200"
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

        #print("points not in the triangle, try again",self.model_path, c_f, c_s)
        return None
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
        elif alpha ==0 or beta ==0 or gamma ==0:
            return True
        else:
            #print("alpha", alpha, "beta", beta, "gamma", gamma)
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
    def normalize(self, speed_l, force_l):
        # in order to save the same topology of the Aluminum Foil
        # set up Alufoil as the standard
        #if speed > 200:
        #print(np.array(speed_l).shape)
        s_old_max, s_old_min = np.max(np.array(speed_l)), np.min(np.array(speed_l))
        f_old_max, f_old_min = np.max(np.array(force_l)), np.min(np.array(force_l))
        max_s, min_s = self.max_s,self.min_s
        max_f, min_f = self.max_f, self.min_f
        def normalized(value, old_min, old_max, new_min, new_max):
            return (value - old_min) * (new_max - new_min) / (old_max - old_min) + new_min 
        normalized_speed = [normalized(value, s_old_min, s_old_max, min_s, max_s) for value in speed_l]
        normalized_force = [normalized(value, f_old_min, f_old_max, min_f, max_f) for value in force_l]
        return normalized_speed, normalized_force

class Morphable_Model(Texturemodel):
    def __init__(self, root_path):
        self.textures = []
        for xmlfi in os.listdir(root_path):
            texture = Texturemodel(os.path.join(root_path, xmlfi))
            self.textures.append(texture)
    #@staticmethod
        self.align = 19
        self.n_components = 18
    def get_ar_features(self, c_f, c_s, alpha, beta, gamma, target= None, source= None, mean_pca = False):
        self.ar_feature= []
        c = 0
        for texture in self.textures:
            if texture.get_back(float(c_f), float(c_s)) is not None:
                if len(texture.get_back(float(c_f), float(c_s)))>=self.align :
                    self.ar_feature.append(texture.get_back(float(c_f), float(c_s))[:self.align]) # align to the same dimension 14
                    c += 1
        #print("valided texture: ", c)
        ar_feat = np.stack(self.ar_feature, axis=0)
        pca, eigen_values, eigenvectors, ar_feat_new = self.pcaf(ar_feat)

        if target is not None and source is not None and mean_pca is False:
            target = np.array(target)
            target = target.reshape(1, -1)
            target_compressed = pca.transform(target)
            source = np.array(source)
            source = source.reshape(1, -1)
            source_compressed = pca.transform(source)
            #x_new_reconstructed = []
            #alphas = alphas.tolist()
            final_compressed = target_compressed * alpha + source_compressed * (1 - alpha)
            x_new_reconstructed = pca.inverse_transform(final_compressed)
            #x_new_reconstructed.append(x_new_reconstruct)
            #import pdb; pdb.set_trace()
        else:
           #meanstaff = pca.mean_
           #meanstaff = meanstaff.reshape(1, -1)
           #print(meanstaff.shape)
           #compress_mean = pca.transform(meanstaff)
           #print(beta, "!!!")
           compress_mean = ar_feat_new.mean(axis = 0)
           compress_mean = compress_mean.reshape(1, -1)
           #print("!", compress_mean)
           compress_mean[:, 0] = compress_mean[:,0] + alpha*(ar_feat_new[:, 0].max() - ar_feat_new[:, 0].min())
           compress_mean[:, 1] = compress_mean[:,1] + beta*(ar_feat_new[:, 1].max() - ar_feat_new[:, 1].min())
           compress_mean[:, 2] = compress_mean[:,2] + gamma*(ar_feat_new[:, 2].max() - ar_feat_new[:, 2].min())
           #compress_mean = compress_mean.reshape(1,-1)
           #compress_mean[:, 1] = compress_mean[:, 1]*+beta# * eigenvectors[1, 0] * np.sqrt(eigen_values[0])
           #compress_mean[:, 2] = compress_mean[:, 2]*+gamma# * eigenvectors[2, 0] * np.sqrt(eigen_values[0])
           x_new_reconstructed = pca.inverse_transform(compress_mean)
           #x_new_reconstructed = pca.inverse_transform(pca.mean_ + alpha * np.dot(eigenvectors, np.sqrt(eigen_values)))

           #import pdb;pdb.set_trace()
        return x_new_reconstructed.squeeze()
    #@staticmethod
    def pcaf(self, ar_features):
        #ar_features = np.array(ar_features)
        pca = PCA(n_components=self.n_components)
        x_new = pca.fit_transform(ar_features) # 100x8
        eigen_values = pca.explained_variance_
        eigenvectors = pca.components_
        return pca, eigen_values, eigenvectors,x_new
   
import numpy as np
import numpy
def lsf2poly(lsf):
    """Convert line spectral frequencies to prediction filter coefficients
    returns a vector a containing the prediction filter coefficients from a vector lsf of line spectral frequencies.
    .. doctest::
        >>> from spectrum import lsf2poly
        >>> lsf = [0.7842 ,   1.5605  ,  1.8776 ,   1.8984,    2.3593]
        >>> a = lsf2poly(lsf)
    # array([  1.00000000e+00,   6.14837835e-01,   9.89884967e-01,
    # 9.31594056e-05,   3.13713832e-03,  -8.12002261e-03 ])
    .. seealso:: poly2lsf, rc2poly, ac2poly, rc2is
    """
    #   Reference: A.M. Kondoz, "Digital Speech: Coding for Low Bit Rate Communications
    #   Systems" John Wiley & Sons 1994 ,Chapter 4

    # Line spectral frequencies must be real.

    lsf = numpy.array(lsf)

    if max(lsf) > numpy.pi or min(lsf) < 0:
        raise ValueError('Line spectral frequencies must be between 0 and pi.')

    p = len(lsf) # model order

    # Form zeros using the LSFs and unit amplitudes
    z  = numpy.exp(1.j * lsf)

    # Separate the zeros to those belonging to P and Q
    rQ = z[0::2]
    rP = z[1::2]

    # Include the conjugates as well
    rQ = numpy.concatenate((rQ, rQ.conjugate()))
    rP = numpy.concatenate((rP, rP.conjugate()))

    # Form the polynomials P and Q, note that these should be real
    Q  = numpy.poly(rQ)
    P  = numpy.poly(rP)

    # Form the sum and difference filters by including known roots at z = 1 and
    # z = -1

    if p%2:
        # Odd order: z = +1 and z = -1 are roots of the difference filter, P1(z)
        P1 = numpy.convolve(P, [1, 0, -1])
        Q1 = Q
    else:
        # Even order: z = -1 is a root of the sum filter, Q1(z) and z = 1 is a
        # root of the difference filter, P1(z)
        P1 = numpy.convolve(P, [1, -1])
        Q1 = numpy.convolve(Q, [1,  1])

    # Prediction polynomial is formed by averaging P1 and Q1

    a = .5 * (P1+Q1)
    return a[0:-1:1] # do not return last element

# lsf = np.array([0.085204, 0.210596, 0.334247, 0.488935, 0.579832, 0.734957, 0.923230,1.184760, 1.197526,1.412573,1.533142,1.687450,1.912737, 2.037198, 2.241818, 2.372196, 2.546994, 2.736498, 2.765299, 2.947802 ])
# lpc =  lsf2poly(lsf)
# print(lpc)

if __name__ == '__main__':
    # #path = input("Please enter the texture xml path:")
    path = './Models/Models10000Hz/XML/Models_Book.xml'
    s_path = './Models/Models10000Hz/XML/Models_Carpet 3.xml'
    name = path.split('/')[-1]
    tarname = name.split(".")[0]
    souname = s_path.split('/')[-1].split(".")[0]
    print("Using ", path.split('/')[-1], "as an example")
    targetmodel = Texturemodel(path) 
    sourcemodel = Texturemodel(s_path)
    print("speed", targetmodel.speeds)
    print("force", targetmodel.forces)
    speed_n , force_n = targetmodel.normalize(targetmodel.speeds, targetmodel.forces) # getting the topology 
    # speed topology x, force topology y
    print("normaliezed speed", speed_n)
    print("normaliezed force", force_n)
    root = './Models/Models10000Hz/XML'
    morph_model = Morphable_Model(root)
    
    # c_f = 2.893
    # c_s = 302.9   

    #sample = 


    mean_pca = True
    if mean_pca:
        save_root = './Models/Morphable_Models/XML/mean_pca'
    else:
        save_root = './Models/Morphable_Models/XML/Book_Carpet'
if mean_pca:
    alphas = np.round(np.linspace(-0.1, 0.1, 20), 2)
    betas= np.round(np.linspace(-0.1, 0.1, 5), 2)
    gammas = np.round(np.linspace(-0.1, 0.1, 3),2)  
    
    for i in range(alphas.shape[0]):
        for j in range(betas.shape[0]):
            for k in range(gammas.shape[0]):
                rendered_arfeatures = []
                rendered_coeffients = []  
                print(alphas[i], "!!!!", betas[j], "!!!!", gammas[k], "!!!!")
                for c, speed in enumerate(force_n):

                    #print("speed",float(force_n[c]), float(speed_n[c]))
                    #targetar = targetmodel.get_back(float(force_n[c]), float(speed_n[c]))[:morph_model.align] # align to the same dimension 14
                    #source = sourcemodel.get_back(float(force_n[c]), float(speed_n[c]))[:morph_model.align]

                    rendered_arfeature = morph_model.get_ar_features(float(force_n[c]), float(speed_n[c]), alphas[i],betas[j],gammas[k],  target=None,source= None, mean_pca = mean_pca)
                    rendered_coeffient = lsf2poly(rendered_arfeature)
                    rendered_arfeatures.append(rendered_arfeature)
                    rendered_coeffients.append(rendered_coeffient)
                # a file 
                savedmodel = Texturemodel(path) 
                if not os.path.isdir(save_root):
                    os.makedirs(save_root)
                name_a = np.int32((alphas+0.1)*200)
                name_b = np.int32((betas+0.1)*50)
                name_g = np.int32((gammas+0.1)*30)
                
                save_path = os.path.join(save_root, "A_"+ str(name_a[i])+"_B_"+str(name_b[j])+"_C_"+str(name_g[k])+ ".xml")            
                savedmodel.change_value(savedmodel.soup, speed_n, force_n, rendered_arfeatures, rendered_coeffients, save_path)
else:
    alphas = np.round(np.linspace(0., 1, 20), 2)

    for i in range(alphas.shape[0]):                
        #print("speed",float(force_n[c]), float(speed_n[c]))
        rendered_arfeatures = []
        rendered_coeffients = []
        for c, speed in enumerate(force_n):
            targetar = targetmodel.get_back(float(force_n[c]), float(speed_n[c]))[:morph_model.align] # align to the same dimension 14
            source = sourcemodel.get_back(float(force_n[c]), float(speed_n[c]))[:morph_model.align]
            rendered_arfeature = morph_model.get_ar_features(float(force_n[c]), float(speed_n[c]), alphas[i],beta = None,gamma = None, target=targetar,source= source, mean_pca = mean_pca)
            rendered_coeffient = lsf2poly(rendered_arfeature)
            rendered_arfeatures.append(rendered_arfeature)
            rendered_coeffients.append(rendered_coeffient)

        #print(alphas[i], "!!!!")
        #import pdb; pdb.set_trace()


         
        savedmodel = Texturemodel(path) 
        name_a = np.int32((alphas)*20)
        save_path = os.path.join(save_root, "A_"+str(name_a[i])+"_B_"+ str(20 - name_a[i]) + ".xml")
        if not os.path.isdir(save_root):
            os.makedirs(save_root)
            
        savedmodel.change_value(savedmodel.soup, speed_n, force_n, rendered_arfeatures, rendered_coeffients, save_path)
    
    #render_arfeature = a.get_ar_features(c_f, c_s, 1, target=targetar)
        
    print("Force {} Netwon, Speed {} mm/s 's AR feature:\n".format(force_n[0], speed_n[0]))
    print("morphaded AR feature:\n", rendered_arfeature)
    print("original AR feature:\n", targetar)
    
    print("morphaded AR coeffient:\n", rendered_coeffient)
    #### generating new texture saved in xml file
    