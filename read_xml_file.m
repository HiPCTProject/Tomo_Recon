%read values from xml files with direct output (easier than xmlreal);
% made first for retrieving motor position if absent from radio header;
% more options to come (maybe);
%
% usage: [ value ] = read_xml_file(filename,xmlnode,what)
%
%         - filename: string of character, full path of xml file to read
%
%         - xmlnode: node to look in within the xml file. example: motor\
%
%         - what: type of information requested. Example: within the motor
%         nodes, two child nodes are motorName and motorPosition;
%         requesting what='sz' as motorName label will return motorPosition
%         of sz
%
% example: 
% 
% [motor_position_value]=read_xml_file('myXmlFile.xml','motor','sz')




function [ value ] = read_xml_file(filename,xmlnode,what,varargin)

switch nargin
    case 4
        ConvertValue=varargin{1};
    otherwise
        ConvertValue='';
end
        

infoLabel = what;  infoCbk = '';  itemFound = false;textdisp='';childText='';value=[];

xDoc = xmlread(filename);

switch xmlnode
    case 'motor'
        
        AllMotors= xDoc.getElementsByTagName(xmlnode);
        NbOfMotors=AllMotors.getLength;
        
        for i=0:AllMotors.getLength-1
            thisListItem = AllMotors.item(i);
            childNode = thisListItem.getFirstChild;
            
            while ~isempty(childNode)
                %Filter out text, comments, and processing instructions.
                if childNode.getNodeType == childNode.ELEMENT_NODE
                    try
                        %Assume that each element has a single org.w3c.dom.Text child
                        childText = char(childNode.getFirstChild.getData);
                        textdisp=char(childNode.getTagName);
                        switch char(childNode.getTagName)
                            case 'motorName' ; itemFound = strcmp(childText,infoLabel);
                            case 'motorPosition' ; infoCbk = childText;
                        end
                    catch
                        childText='Empty';
                    end
                end
                childNode = childNode.getNextSibling;
                %fprintf('round %1.0f checking: %s %s %s \n',i,textdisp, childText,infoCbk);
            end
            
            if itemFound break; else infoCbk = ''; end
        end
        value=str2num(infoCbk);
        
    case 'acquisition'
        AllItems= xDoc.getElementsByTagName(xmlnode);
        NbOfItems=AllItems.getLength;
        
        for i=0:AllItems.getLength-1
            thisListItem = AllItems.item(i);
            childNode = thisListItem.getFirstChild;
            
            while ~isempty(childNode)
                %Filter out text, comments, and processing instructions.
                if childNode.getNodeType == childNode.ELEMENT_NODE
                    %Assume that each element has a single org.w3c.dom.Text child
                    try
                        childText = char(childNode.getFirstChild.getData);
                        char(childNode.getTagName);
                        switch char(childNode.getTagName)
                            case infoLabel ; itemFound = 1; infoCbk=childText;
                        end
                    catch
                        childText='Empty';
                    end
                end
                childNode = childNode.getNextSibling;
                %fprintf('round %1.0f checking: %s %s %s \n',i,textdisp, childText,infoCbk);
            end
            
            if itemFound break; else infoCbk = ''; end
        end
        value=infoCbk;     

        
    case 'projectionSize'
        
        AllItems= xDoc.getElementsByTagName(xmlnode);
        NbOfItems=AllItems.getLength;
        
        for i=0:AllItems.getLength-1
            thisListItem = AllItems.item(i);
            childNode = thisListItem.getFirstChild;
            
            while ~isempty(childNode)
                %Filter out text, comments, and processing instructions.
                if childNode.getNodeType == childNode.ELEMENT_NODE
                    try
                        %Assume that each element has a single org.w3c.dom.Text child
                        childText = char(childNode.getFirstChild.getData);
                        char(childNode.getTagName);
                        switch char(childNode.getTagName)
                            case infoLabel ; itemFound = 1; infoCbk=childText;
                        end
                    catch
                        childText='Empty';
                    end
                end
                childNode = childNode.getNextSibling;
                %fprintf('round %1.0f checking: %s %s %s \n',i,textdisp, childText,infoCbk);
            end
            
            if itemFound break; else infoCbk = ''; end
        end
        value=infoCbk;
        
    otherwise
        
        AllItems= xDoc.getElementsByTagName(xmlnode);
        NbOfItems=AllItems.getLength;
        
        for i=0:AllItems.getLength-1
            thisListItem = AllItems.item(i);
            childNode = thisListItem.getFirstChild;
            
            while ~isempty(childNode)
                %Filter out text, comments, and processing instructions.
                if childNode.getNodeType == childNode.ELEMENT_NODE
                    %Assume that each element has a single org.w3c.dom.Text child
                    childText = char(childNode.getFirstChild.getData);
                    char(childNode.getTagName);
                    switch char(childNode.getTagName)
                        case infoLabel ; itemFound = 1; infoCbk=childText;
                    end
                end
                childNode = childNode.getNextSibling;
                %fprintf('round %1.0f checking: %s %s %s \n',i,textdisp, childText,infoCbk);
            end
            
            if itemFound break; else infoCbk = ''; end
        end
        value=infoCbk;        
        
        switch ConvertValue
            case 'numeric'
            value=str2num(value)   ; 
        end
end %end of switch
    
end %end of function

