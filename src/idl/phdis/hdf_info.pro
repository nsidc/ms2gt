; HDF_info procedure - from IDL's "examples/data_access/sdf" folder.
;
pro HDF_info,filename,OUTFILE=outfile,check_dfan=check_dfan,check_dfr8=check_dfr8,check_df24=check_df24,check_RIG=check_RIG,$
	check_AN=check_AN,check_GR=check_GR
if not keyword_set(check_dfan) then check_dfan=0
if not keyword_set(check_dfr8) then check_dfr8=0
if not keyword_set(check_df24) then check_df24=0
if not keyword_set(check_RIG) then check_RIG=0
if n_elements(check_GR) eq 0 then check_GR=1
if n_elements(check_AN) eq 0 then check_AN=1
;
; The DFAN, DFR8, DF24, and RIG calls are now obselete do to
; the new HDF AN and GR interfaces. These keywords provide for
; backwards compatibility
;

; displays Raster,SD,MSDS and Vset information about filename,
; in tabular format

;	Check for required number of input parameters
if n_params() lt 1  then begin
	printf,uid,'usage:  HDF_info,filename [,OUTFILE=outfile]'
	printf,uid,"   ARGUMENTS : filename : string name of HDF file"
	printf,uid,"	  KEYWORDS:"
	printf,uid,"		OUTFILE : filename for output information"
	printf,uid,"			to be written to (optional)"
	printf,uid,'   OUTPUTS: the HDF metadata for this file,'
	printf,uid,'		always to the display, and possibly'
	printf,uid,'		to the outfile specified'
	printf,uid,"EXAMPLE:  HDF_info,'demo.hdf'"
	printf,uid,'          will display the HDF metadata for this file'
	return
endif
if not keyword_set(outfile) then uid=-1 else $
   openw,uid,outfile,/get_lun
;
;    Create some useful formats
;
F1='("	",A,I4)'
F2='("-----",A,A,"-----")'
F3='("-----",A,"-----")'
F_label='("	-----",A,A," = ",A)'
FI='(A24," ",A8," ",I6," ",I)'
FS='(A24," ",A8," ",I6," ",A)'
FF='(A24," ",A8," ",I6," ",F)'
FD='(A24," ",A8," ",I6," ",D)'
F4='(A24," ",A8," ",I6)'
F5='(A24," ",A7," ",A7," ",A39)'
F5L='(A24," ",A8," ",A8,"",A30)'
F80='(80("-"))'
F80E='(80("="))'

;	Check that it is HDF !
if HDF_ishdf(filename) ne 1 then begin
	message,"File "+filename+" is not an HDF file."
endif

;      Open the HDF file readonly
  fileid=HDF_OPEN(filename,/read)
	printf,uid," *****BEGINNING OF HDF_INFORMATION***** "
	printf,uid
        printf,uid,FORMAT=F80E
	printf,uid," FILENAME       : ",filename

;	Get and report the number of free palettes.
  numfpals=HDF_dfp_npals(filename)>0
	printf,uid,FORMAT=F80E
	printf,uid,"# of HDF free palettes = ",numfpals,FORMAT=F1
;
; Peruse the file for AN annotations
;
if check_AN then begin
 	an_id=HDF_AN_START(fileid)
                result=HDF_AN_FILEINFO(an_id,n_file_labels,n_file_descs,$
                                             n_data_labels,n_data_descs)

                printf,uid,FORMAT=F80E
                printf,uid,"# of HDF-AN file descriptions = ",n_file_descs,FORMAT=F1
                printf,uid,"# of HDF-AN data descriptions = ",n_data_descs,FORMAT=F1
                printf,uid,"# of HDF-AN file labels = ",n_file_labels,FORMAT=F1

                for i=0,n_file_labels-1 do begin
                        ann_id=HDF_AN_SELECT(an_id,i,2)
                                result=HDF_AN_READANN(ann_id,annotation)
                                if result ge 0 then $
                                 printf,uid,'File Label #',strtrim(string(i),2),annotation,FORMAT=F_label
                        HDF_AN_ENDACCESS,ann_id
                endfor
                printf,uid,"# of HDF-AN data labels = ",n_data_labels,FORMAT=F1
                for i=0,n_data_labels-1 do begin
                        ann_id=HDF_AN_SELECT(an_id,i,0)
                                result=HDF_AN_READANN(ann_id,annotation)
                                if result ge 0 then $
                        	   printf,uid,'Data Label #',strtrim(string(i),2),annotation,FORMAT=F_label
                        HDF_AN_ENDACCESS,ann_id
                endfor

        HDF_AN_END,an_id
endif

if check_DFAN then begin
;
; THE DFAN interface is obsolete, do not check it by default
;
;	Get the number of file ids and read them.
  numid=HDF_number(fileid,tag=100)>0
	printf,uid,FORMAT=F80E
	printf,uid,"# of file file ids = ",numid,FORMAT=F1
	if numid ne 0 then begin
	if numid eq 1 then begin
	    HDF_dfan_getfid,filename,fid,/first
	    printf,uid,"File Id",FORMAT=F3 & print,strcompress(string(fid))
	endif else begin
	    printf,uid,"File Id",string(1),FORMAT=F2
	    HDF_dfan_getfid,filename,fid,/first & printf,uid,strcompress(string(fid))
	    for i=2,numid do  begin
	     printf,uid,"File Id",strtrim(string(i)),FORMAT=F2
	     HDF_dfan_getfid,filename,fid & printf,uid,strcompress(string(fid))
	    endfor
	endelse
	endif

;	Get the number of file descriptions and read them.
  numdesc=HDF_number(fileid,tag=101)>0
	printf,uid,FORMAT=F80E
	printf,uid,"# of file descriptions = ",numdesc,FORMAT=F1
	if numdesc ne 0 then begin
	if numdesc eq 1 then begin
	    HDF_dfan_getfds,filename,desc,/first,/string
	    printf,uid,"File Description",FORMAT=F3 & print,desc
	endif else begin
	     printf,uid,"File Description",string(1),FORMAT=F2
	    HDF_dfan_getfds,filename,desc,/first,/string & printf,uid,desc
	    for i=2,numdesc do  begin
	     printf,uid,"File Description",string(i),FORMAT=F2
	     HDF_dfan_getfds,filename,desc,/string & printf,uid,desc
	    endfor
	endelse
	endif
endif ; check_DFAN
if check_dfr8 then begin
;
; THE DFR8 interface is obsolete, do not check it by default
;
;       Get info on 8-bit images
;
        HDF_DFR8_RESTART
        NIMAGES=HDF_DFR8_NIMAGES(filename)
        printf,uid,FORMAT=F80E
        printf,uid,'# of 8-bit images=',NIMAGES,FORMAT=F1
        if NIMAGES gt 0 then begin
           printf,uid
           has_p=["No Palette. ","a Palette."]
           for i = 0, NIMAGES -1 do begin
               HDF_DFR8_GETINFO,filename,width,height,has_pal
               printf,uid,i,width,height,has_p[has_pal],$
                  FORMAT='(5X,"IMAGE # ",I3," is ",I4," by ",I3," Has ",A)'
           endfor
        endif
endif
if check_df24 then begin
;
;       Get info on 24-bit images
;
; THE DF24 interface is obsolete, do not check it by default

        HDF_DF24_RESTART
        NIMAGES=HDF_DF24_NIMAGES(filename)
        printf,uid,FORMAT=F80E
        printf,uid,'# of 24-Bit images =',NIMAGES,FORMAT=F1
        if NIMAGES gt 0 then begin
           printf,uid
           for i =0, NIMAGES-1 do begin
           HDF_DF24_GETINFO,filename,width,height,interlace
           printf,uid,'IMAGE #',i,' is ',width,' by ',height,'. Interlace = ',$
                  interlace,FORMAT='(5X,A,I3,A,I4,A,I4,A,I1)'
           endfor
        endif
endif

;
; Check for HDF-GR images
;
if check_GR then begin
GR_0='("	  --- ",A," ",A)
GR_1='("	 	 ",A," = ",A)'
GR_2='("		",A," = [",8(I5,:,","),$)'
        printf,uid,FORMAT=F80E
	gr_id=HDF_GR_START(fileid)
		result=HDF_GR_FILEINFO(gr_id,n_images,n_file_attrs)
        	printf,uid,'# of HDF-GR images =',n_images,FORMAT=F1
		for i=0,n_images-1 do begin
			ri_id=HDF_GR_SELECT(gr_id,i)
			printf,uid,'Image # ',strtrim(string(i),2),FORMAT=GR_0
				result=HDF_GR_GETIMINFO(ri_id,name,ncomp,type,mode,dim_sizes,num_attrs)
			printf,uid,'Name',name,FORMAT=GR_1
			printf,uid,'Number of Components',strtrim(string(ncomp),2),FORMAT=GR_1
			printf,uid,'HDF Data Type',strtrim(string(type),2),FORMAT=GR_1
			printf,uid,'Interlace Mode',strtrim(string(mode),2),FORMAT=GR_1
			DS="["+strcompress(string(dim_sizes,format='(8(I,:,","))'),/remove_all)+"]"
			printf,uid,'Dimension Sizes',DS,FORMAT=GR_1
			printf,uid,'Number of Attributes',strtrim(string(num_attrs),2),FORMAT=GR_1
			HDF_GR_ENDACCESS,ri_id
		endfor
		if n_images ge 1 then printf,uid
        	printf,uid,'# of HDF-GR file attributes =',n_file_attrs,FORMAT=F1
		for i=0,n_file_attrs-1 do begin
			result=HDF_GR_ATTRINFO(gr_id,i,name,type,count)
			printf,uid,'Attribute # ',strtrim(string(i),2),FORMAT=GR_0
			printf,uid,'Name',name,FORMAT=GR_1
			printf,uid,'HDF Data Type',strtrim(string(type),2),FORMAT=GR_1
			printf,uid,'Number of elements',strtrim(string(count),2),FORMAT=GR_1
		endfor
	HDF_GR_END,gr_id
endif

if check_RIG then begin
;	Get the number of RIG groups in the file
        numrig=HDF_number(fileid,tag=306)>0
	printf,uid,FORMAT=F80E
	printf,uid,"# of RIG groups = ",numrig,FORMAT=F1
	if numrig gt 0 then begin
                printf,uid
		result=HDF_dfan_lablist(filename,306,reflist,RIGLABELS)
		for i=0,n_elements(reflist)-1 do begin
                    printf,uid,i,reflist[i],string(RIGLABELS[i]),$
                     FORMAT='(5X,"RIG Group # ",I2,": Ref # ="'+$
                      ',I3," : Label = ",A)'
                endfor
	endif
        printf,uid,FORMAT=F80E
endif

;
;	Get the number of SDSs in the file
;
sd_id=HDF_SD_START(filename,/read)
HDF_SD_FILEINFO,sd_id,nmfsds,nglobatts
;	Get the number of MFSDs in the file
        printf,uid,FORMAT=F80E
	printf,uid,"# of MFSD = ",nmfsds,FORMAT=F1

	if nmfsds gt 0 then begin
         printf,uid
         printf,uid,FORMAT=F80
         printf,uid,"          Information about MFHDF DataSets "
         printf,uid,FORMAT=F80
	 printf,uid,"    NAME   IDL_Type   HDF_Type      Rank   Dimensions"
         printf,uid,"---------  -------- ----------      ----  ------------"
         printf,uid,"           ------------- Atrribute Info -------------"
         printf,uid
         FSD='(A10,"  ",A8,"  ",I4,"  ",I4)'
	 for i=0,nmfsds-1 do begin
	  sds_id=HDF_SD_SELECT(sd_id,i)
          HDF_SD_GETINFO,sds_id,name=n,ndims=r,type=t,natts=nats,$
                         hdf_type=h,unit=u
          if r gt 0 then HDF_SD_GETINFO,sds_id,dims=dims else dims=0

          if r le 1 then FSD='(A10," ",A8," ",A12,3X,I4,3X,"[",I4,"] ",A)' $
                   else FSD='(A10," ",A8," ",A12,3X,I4,3X,"["'+$
                        STRING(r-1)+'(I4,","),I4,"] ",A)'

          printf,uid,n,t,h,r,dims,u,FORMAT=FSD
          for j=0,nats-1 do begin
	    HDF_SD_ATTRINFO,sds_id,j,name=n,type=t,count=c,data=d,$
                            hdf_type=h

      	    CASE t OF
		 'FLOAT':  FB='G)'
                 'DOUBLE': FB='G)'
                 'STRING': FB='A)'
		 ELSE:     FB='I)'
            ENDCASE

	    printf,uid,j+1,n,d[0],$
             FORMAT='(11X,"Attribute => ",I3,2X,A13," = ",'+FB

	   for k=1,n_elements(d)-1 do printf,uid,d[k],FORMAT='(45X,'+FB
	  endfor
	  HDF_SD_ENDACCESS,sds_id
          printf,uid,FORMAT='(10X,70("_"))'
	 endfor
	endif
	printf,uid,FORMAT=F80E
	printf,uid,"# of Global Attributes ",nglobatts,FORMAT=F1
	if nglobatts gt 0 then begin
         printf,uid
	 printf,uid,"------------------------------------------------"
	 printf,uid,'Name','Type','Elements','Value',FORMAT=F5L
	 printf,uid,FORMAT=F80
	 printf,uid
	 for i=0,nglobatts-1 do begin
		HDF_SD_ATTRINFO,sd_id,i,name=n,type=t,count=c,data=d
	   if (t eq 'STRING' ) then printf,uid,strtrim(n),t,c,d[0,0],FORMAT=FS else $
	   if (t eq 'FLOAT' )  then printf,uid,strtrim(n),t,c,d[0,0],FORMAT=FF else $
	   if (t eq 'DOUBLE' ) then printf,uid,strtrim(n),t,c,d[0,0],FORMAT=FD else $
		printf,uid,strtrim(n),t,c,d[0,0],FORMAT=FI
	 endfor
	endif
    HDF_SD_END,sd_id
    printf,uid,FORMAT=F80E

; START VGROUP SEARCH
;
       lvgs=HDF_VG_LONE(fileid)
        if lvgs[0] eq -1 then  begin
            num_lone_vgroups=0
	    printf,uid,"# of Parent Vgroups",num_lone_vgroups,FORMAT=F1
            printf,uid,FORMAT=F80E
        endif else begin
            num_lone_vgroups=n_elements(lvgs)
	    printf,uid,"# of Parent Vgroups",num_lone_vgroups,FORMAT=F1
            printf,uid,FORMAT=F80
            printf,uid," Vgroup #   # of Members             Class                   Name "
  	    printf,uid,"---------  ---------------------------------------------------------"
 for j=0,num_lone_vgroups-1 do begin
                 gid=HDF_VG_ATTACH(fileid,lvgs[j])
                  HDF_VG_GETINFO,gid,NAME=gNAME,CLASS=gCLASS,NENTRIES=gNENTRIES
                  printf,uid,j,gNENTRIES,gNAME,gCLASS,FORMAT='(2X,I3,10X,I3,8X,A20,2X,A20)'
                 HDF_VG_DETACH,gid
        	endfor
	    printf,uid,'===================================================================='
         endelse
	printf,uid," *****END OF HDF_INFORMATION***** "
	HDF_close,fileid

 if uid ne -1 then free_lun,uid
end
