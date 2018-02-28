for i=1:15
    for k={'A','B'}
        if i<10
            zk='0';
        else
            zk='';
        end
        mkdir(sprintf(['AR_',zk,num2str(i),k{:}]));
    end
end

for i=1:15
    for k={'A','B'}
        if i<10
            zk='0';
        else
            zk='';
        end
        f1=['/data3/Wanja/Alpha_Retro_Analysis/EEG/AR_',zk,num2str(i),k{:},'/AR_',zk,num2str(i),k{:},'_CleanBeforeICA.fdt'];
        f2=['/data3/Wanja/Alpha_Retro_Analysis/EEG/AR_',zk,num2str(i),k{:},'/AR_',zk,num2str(i),k{:},'_CleanBeforeICA.set'];
        gdir=['/data3/Wanja/Sciebo/tempdata/AR_',zk,num2str(i),k{:},'/'];
        copyfile(f1,gdir);
        copyfile(f2,gdir);
    end
end
