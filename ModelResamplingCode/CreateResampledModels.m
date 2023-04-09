function CreateResampledModels(Fs_mod)
%CREATERESAMPLEDMODELS(Fs_mod) Resamples the original models at 10kHz and
%returns models at the desired sampling rate for rendering
%Fs_mod = desired sampling rate in Hz (must be less than 10 kHz)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%COPYRIGHT AND PERMISSION NOTICE
%Penn Software The Penn Haptic Texture Toolkit
%Copyright (C) 2013 The Trustees of the University of Pennsylvania
%All rights reserved.

%See copyright and permission notice at the end of this file.

%Report bugs to Heather Culbertson (hculb@seas.upenn.edu, +1 215-573-6748) or Katherine J. Kuchenbecker (kuchenbe@seas.upenn.edu, +1 215-573-2786)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Folders for accessing and storing files
origXMLFolder = '..\Models\Models10000Hz\XML'; % folder where original xml files are stored

d = dir(strcat(origXMLFolder,'\*.xml'));% Find names of all XML model files at 10000 Hz

modelFolder = strrep('..\Models\ModelsFSHz','FS',num2str(Fs_mod));
mkdir(modelFolder); % make folder to store new model files
mkdir(strcat(modelFolder),'\XML'); % sub-folder to store XML files
mkdir(strcat(modelFolder),'\HTML'); % sub-folder to store HTML files

% folder names for storing and accessing files 
baseHTMLFilename = strcat(modelFolder,'\HTML\Models_MATER.html');
baseXMLFilename = strcat(modelFolder,'\XML\Models_MATER.xml');

styleFile = 'modelXSL_createHTML.xsl'; % file for parsing xml to html

%% Loop through all materials
for matNum = 1:length(d)
    %% Read in XML file for material   
    matFilename = strcat(origXMLFolder,'\',d(matNum).name);  
    xDoc = xmlread(matFilename);

    %% Pull data from XML file

    mater = readValueXML(xDoc,'material'); % material name
    a_units = readValueXML(xDoc,'AccelUnits'); % acceleration units
    speed_units = readValueXML(xDoc,'SpeedUnits'); % speed units
    force_units = readValueXML(xDoc,'ForceUnits'); % force units
    Fs_orig = str2num(readValueXML(xDoc,'SampleRate')); % sample rate
    mu = str2num(readValueXML(xDoc,'mu')); % friction coefficient
    ImageFilename = readValueXML(xDoc,'htmlPicture'); % texture image filename for display in html
    LinuxImageFilename = readValueXML(xDoc,'htmlLinuxPicture'); % texture image filename for display in html for Linux
    RenderImageFilename = readValueXML(xDoc,'renderPicture'); % texture image filename for display in rendering
    numMod = str2num(readValueXML(xDoc,'numMod')); % number of models
    numTri = str2num(readValueXML(xDoc,'numTri')); % number of Delaunay triangles
    speedMod = readArrayXML(xDoc,'speedList'); % list of model speeds
    forceMod = readArrayXML(xDoc,'forceList'); % list of model forces
    dt = readArrayXML(xDoc,'tri')'; % delaunay triangulation
    TriImageFilename = readValueXML(xDoc,'DTpicture'); % delaunay triangulation image
    LinuxTriImageFilename = readValueXML(xDoc,'LinuxDTpicture'); % delaunay triangulation image for Linux
    numCoeff = str2num(readValueXML(xDoc,'numARCoeff')); % number of AR coefficients

    modelItem = xDoc.getElementsByTagName('model');
    model_info_10000 = cell(numMod,1);
    %get information for each individual model
    for mi = 0:modelItem.getLength-1 
        currentModelItem = modelItem.item(mi);
        model_info_10000{mi+1}.var = str2num(readValueXML(currentModelItem,'var')); % model variance
        model_info_10000{mi+1}.speed = str2num(readValueXML(currentModelItem,'speedMod')); % model speed
        model_info_10000{mi+1}.force = str2num(readValueXML(currentModelItem,'forceMod')); % model force
        model_info_10000{mi+1}.A = readArrayXML(currentModelItem,'ARcoeff'); % array of AR coefficients
        model_info_10000{mi+1}.A_lsf = readArrayXML(currentModelItem,'ARlsf'); % array of AR line spectral frequencies
        model_info_10000{mi+1}.C = 1; % model numerator (no MA coefficients)
    end

    %% Create downsampled models

    model_info = resampleModels(model_info_10000,Fs_orig,Fs_mod);

    %% Write and save new XML and HTML files

    % create unique filenames for each material
    HTMLFilename = strrep(baseHTMLFilename,'MATER',mater);
    XMLFilename = strrep(baseXMLFilename,'MATER',mater);

    %create document node and root element, modelSet
    docNode = com.mathworks.xml.XMLUtils.createDocument('modelSet');

    %identify the root element, and set the texture attribute
    modelSet = docNode.getDocumentElement;
    modelSet.setAttribute('texture',num2str(matNum-1));

    %material name
    thisElement = docNode.createElement('material');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',mater)));
    modelSet.appendChild(thisElement);

    %units
    thisElement = docNode.createElement('AccelUnits');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',a_units)));
    modelSet.appendChild(thisElement);
    thisElement = docNode.createElement('SpeedUnits');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',speed_units)));
    modelSet.appendChild(thisElement);
    thisElement = docNode.createElement('ForceUnits');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',force_units)));
    modelSet.appendChild(thisElement);

    %sampling rate
    thisElement = docNode.createElement('SampleRate');
    thisElement.appendChild(docNode.createTextNode(sprintf('%d',Fs_mod)));
    modelSet.appendChild(thisElement);

    %friction coefficient
    thisElement = docNode.createElement('mu');
    thisElement.appendChild(docNode.createTextNode(sprintf('%f',mu)));
    modelSet.appendChild(thisElement);
    
    %image file for HTML
    thisElement = docNode.createElement('htmlPicture');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',ImageFilename)));
    modelSet.appendChild(thisElement);
    
    %image file for HTML in Linux
    thisElement = docNode.createElement('htmlLinuxPicture');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',LinuxImageFilename)));
    modelSet.appendChild(thisElement);
    
    %image file for rendering
    thisElement = docNode.createElement('renderPicture');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',RenderImageFilename)));
    modelSet.appendChild(thisElement);

    %number of models
    thisElement = docNode.createElement('numMod');
    thisElement.appendChild(docNode.createTextNode(sprintf('%d',numMod)));
    modelSet.appendChild(thisElement);

    %number of triangles
    thisElement = docNode.createElement('numTri');
    thisElement.appendChild(docNode.createTextNode(sprintf('%d',numTri)));
    modelSet.appendChild(thisElement);

    %maximum speed
    thisElement = docNode.createElement('maxSpeed');
    thisElement.appendChild(docNode.createTextNode(sprintf('%f',max(speedMod))));
    modelSet.appendChild(thisElement);

    %maximum force
    thisElement = docNode.createElement('maxForce');
    thisElement.appendChild(docNode.createTextNode(sprintf('%f',max(forceMod))));
    modelSet.appendChild(thisElement);

    %list of speeds
    thisElement = docNode.createElement('speedList');
    thisElement.setAttribute('type','array');
    for si=1:numMod
        thisSubElement = docNode.createElement('value');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%f',speedMod(si))));
        thisElement.appendChild(thisSubElement);
    end
    modelSet.appendChild(thisElement);

    %list of forces
    thisElement = docNode.createElement('forceList');
    thisElement.setAttribute('type','array');
    for fi=1:numMod
        thisSubElement = docNode.createElement('value');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%f',forceMod(fi))));
        thisElement.appendChild(thisSubElement);
    end
    modelSet.appendChild(thisElement);

    %list 1 of triangle vertices
    for dti=1:numTri
        thisElement = docNode.createElement('tri');
        thisElement.setAttribute('type','array');    

        thisSubElement = docNode.createElement('value');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%d',dt(dti,1))));
        thisElement.appendChild(thisSubElement);

        thisSubElement = docNode.createElement('value');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%d',dt(dti,2))));
        thisElement.appendChild(thisSubElement);

        thisSubElement = docNode.createElement('value');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%d',dt(dti,3))));
        thisElement.appendChild(thisSubElement);

        modelSet.appendChild(thisElement);
    end

    %DT image file
    thisElement = docNode.createElement('DTpicture');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',TriImageFilename)));
    modelSet.appendChild(thisElement);
    
    %DT image file
    thisElement = docNode.createElement('LinuxDTpicture');
    thisElement.appendChild(docNode.createTextNode(sprintf('%s',LinuxTriImageFilename)));
    modelSet.appendChild(thisElement);

    for j = 1:numMod
        % pull the information from the model file
        A = model_info{j}.A;
        C = model_info{j}.C;
        kGain = model_info{j}.k;

        var = model_info{j}.var;

        numCoeff = length(A)-1;
        numMA = length(C);
        speed = model_info{j}.speed;
        force = model_info{j}.force;

        LSF = poly2lsf(A);
        MALSF = poly2lsf(C);

        if j==1
            %number of coefficients
            thisElement = docNode.createElement('numARCoeff');
            thisElement.appendChild(docNode.createTextNode(sprintf('%d',numCoeff)));
            modelSet.appendChild(thisElement);
            thisElement = docNode.createElement('numMACoeff');
            thisElement.appendChild(docNode.createTextNode(sprintf('%d',numMA-1)));
            modelSet.appendChild(thisElement);
        end

        %each model
        thisElement = docNode.createElement('model');
        %model number
        thisSubElement = docNode.createElement('modNum');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%d',j)));
        thisElement.appendChild(thisSubElement);

        %array of AR coefficients
        thisSubElement = docNode.createElement('ARcoeff');
        for ari = 1:numCoeff+1
            thisSubSubElement = docNode.createElement('value');
            thisSubSubElement.appendChild(docNode.createTextNode(sprintf('%0.20f',A(ari))));
            thisSubElement.appendChild(thisSubSubElement);
        end
        thisElement.appendChild(thisSubElement);

        %array of AR LSFs
        thisSubElement = docNode.createElement('ARlsf');
        for li = 1:numCoeff
            thisSubSubElement = docNode.createElement('value');
            thisSubSubElement.appendChild(docNode.createTextNode(sprintf('%f',LSF(li))));
            thisSubElement.appendChild(thisSubSubElement);
        end
        thisElement.appendChild(thisSubElement);

        %array of MA coefficients
        thisSubElement = docNode.createElement('MAcoeff');
        for mai = 1:numMA
            thisSubSubElement = docNode.createElement('value');
            thisSubSubElement.appendChild(docNode.createTextNode(sprintf('%0.20f',C(mai))));
            thisSubElement.appendChild(thisSubSubElement);
        end
        thisElement.appendChild(thisSubElement);

        %array of MA LSFs
        thisSubElement = docNode.createElement('MAlsf');
        for lmi = 1:numMA-1
            thisSubSubElement = docNode.createElement('value');
            thisSubSubElement.appendChild(docNode.createTextNode(sprintf('%f',MALSF(lmi))));
            thisSubElement.appendChild(thisSubSubElement);
        end
        thisElement.appendChild(thisSubElement);

        thisElement.appendChild(thisSubElement);
        %variance value
        thisSubElement = docNode.createElement('var');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%f',var)));
        thisElement.appendChild(thisSubElement);
        %gain value
        thisSubElement = docNode.createElement('gain');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%f',kGain)));
        thisElement.appendChild(thisSubElement);
        %model speed value
        thisSubElement = docNode.createElement('speedMod');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%f',speed)));
        thisElement.appendChild(thisSubElement);
        %model force value
        thisSubElement = docNode.createElement('forceMod');
        thisSubElement.appendChild(docNode.createTextNode(sprintf('%f',force)));
        thisElement.appendChild(thisSubElement);
        modelSet.appendChild(thisElement);
    end

    xmlwrite(XMLFilename,docNode); %write model XML file
    result = xslt(XMLFilename,styleFile,HTMLFilename); %write model HTML file

end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COPYRIGHT AND PERMISSION NOTICE
% Penn Software The Penn Haptic Texture Toolkit
% Copyright (C) 2013 The Trustees of the University of Pennsylvania
% All rights reserved.
% 
% The Trustees of the University of Pennsylvania (“Penn”) and Heather Culbertson, Juan Jose Lopez Delgado, and Katherine J. Kuchenbecker, the developer (“Developer”) of Penn Software The Penn Haptic Texture Toolkit (“Software”) give recipient (“Recipient”) and Recipient’s Institution (“Institution”) permission to use, copy, and modify the software in source and binary forms, with or without modification for non-profit research purposes only provided that the following conditions are met:
% 
% 1)	All copies of Software in binary form and/or source code, related documentation and/or other materials provided with the Software must reproduce and retain the above copyright notice, this list of conditions and the following disclaimer.
% 
% 2)	Recipient shall have the right to create modifications of the Software (“Modifications”) for their internal research and academic purposes only. 
% 
% 3)	All copies of Modifications in binary form and/or source code and related documentation must reproduce and retain the above copyright notice, this list of conditions and the following disclaimer.
% 
% 4)	Recipient and Institution shall not distribute Software or Modifications to any third parties without the prior written approval of Penn.
% 
% 5)	Recipient will provide the Developer with feedback on the use of the Software and Modifications, if any, in their research.  The Developers and Penn are permitted to use any information Recipient provides in making changes to the Software. All feedback, bug reports and technical questions shall be sent to: 
% 
% Heather Culbertson, hculb@seas.upenn.edu, +1 215-573-6748
% Katherine J. Kuchenbecker, kuchenbe@seas.upenn.edu, +1 215-573-2786
% 
% 6)	Recipient acknowledges that the Developers, Penn and its licensees may develop modifications to Software that may be substantially similar to Recipient’s modifications of Software, and that the Developers, Penn and its licensees shall not be constrained in any way by Recipient in Penn’s or its licensees’ use or management of such modifications. Recipient acknowledges the right of the Developers and Penn to prepare and publish modifications to Software that may be substantially similar or functionally equivalent to your modifications and improvements, and if Recipient or Institution obtains patent protection for any modification or improvement to Software, Recipient and Institution agree not to allege or enjoin infringement of their patent by the Developers, Penn or any of Penn’s licensees obtaining modifications or improvements to Software from the Penn or the Developers.
% 
% 7)	Recipient and Developer will acknowledge in their respective publications the contributions made to each other’s research involving or based on the Software. The current citations for Software are:
% 
% Heather Culbertson, Juan Jose Lopez Delgado, and Katherine J. Kuchenbecker. One Hundred Data-Driven Haptic Texture Models and Open-Source Methods for Rendering on 3D Objects. In Proc. IEEE Haptics Symposium, February 2014.
% 
% 8)	Any party desiring a license to use the Software and/or Modifications for commercial purposes shall contact The Center for Technology Transfer at Penn at 215-898-9591.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS, CONTRIBUTORS, AND THE TRUSTEES OF THE UNIVERSITY OF PENNSYLVANIA "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER, CONTRIBUTORS OR THE TRUSTEES OF THE UNIVERSITY OF PENNSYLVANIA BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
