addLoadEvent(init);
var isTiming=false;
var embedVideoCounter=0;
var curSWFHash;
var swfinfo=[];
var swfInfoByHash={};
var flashvarObjectIDSBySWFHash=[];
var flashvarKeyValueSetsBySWFHash=[];
var defaulFlashvarKeyValueSetsBySWFHash=[]
var createdDefaultFlashVars=[];
var isPreviewPage;
var swfTabSWFList;
var flashVarSWFList;
var inFlashvarsTab=false;
var keysModalShown;

var defaultFlashVars=[
	{key:"clickTag",value:"http://www.mccannsf.com/clickTag"},
	{key:"clickTAG",value:"http://www.mccannsf.com/clickTAG_"},
	{key:"clickTag1",value:"http://www.mccannsf.com/clickTag1"},
	{key:"clickTag2",value:"http://www.mccannsf.com/clickTag2"},
	{key:"clickTag3",value:"http://www.mccannsf.com/clickTag3"},
	{key:"clickTag4",value:"http://www.mccannsf.com/clickTag4"},
	{key:"clickTag5",value:"http://www.mccannsf.com/clickTag5"}
];

function addFlashVar(key,value,saveBefore)
{
	if(saveBefore)onFlashVarSWFListChange();
	var nh;
	var keyID=randomUUID();
	var valueID=randomUUID();
	if(!flashvarObjectIDSBySWFHash[curSWFHash])flashvarObjectIDSBySWFHash[curSWFHash]=[];
	flashvarObjectIDSBySWFHash[curSWFHash].push({key:keyID,value:valueID});
	if(key&&value) nh = "<table style='width:100%'><tr><td width='1'><input size='10' type='text' id='"+keyID+"' value='"+key+"'/></td><td>&nbsp;</td><td width='100%'><input type='text' id='"+valueID+"' style='width:100%' value='"+value+"' /></td></tr></table>";
	else nh = "<table style='width:100%'><tr><td width='1'><input size='10' type='text' id='"+keyID+"'/></td><td>&nbsp;</td><td width='100%'><input type='text' id='"+valueID+"' style='width:100%' /></td></tr></table>";
	$(curSWFHash).innerHTML+=nh;
}

function saveCurrentFlashVarData()
{
	var i=0,l=0;
	if(flashvarObjectIDSBySWFHash[curSWFHash] && flashvarObjectIDSBySWFHash[curSWFHash].length>0)
	{
		var keyTFValue,valueTFValue,ids;
		l=flashvarObjectIDSBySWFHash[curSWFHash].length;
		flashvarKeyValueSetsBySWFHash[curSWFHash]=[];
		for(i;i<l;i++)
		{
			ids=flashvarObjectIDSBySWFHash[curSWFHash][i];
			if(!$(ids.key))continue;
			if(!$(ids.value))continue;
			keyTFValue=$(ids.key).value;
			valueTFValue=$(ids.value).value;
			if(keyTFValue==""&&valueTFValue=="") continue;
			flashvarKeyValueSetsBySWFHash[curSWFHash].push({keyID:ids.key,valueID:ids.value,key:keyTFValue,value:valueTFValue});
		}
	}
}

function onFlashVarSWFListChange()
{
	saveCurrentFlashVarData();
	var list=flashVarSWFList;
	curSWFHash=list.options[list.selectedIndex].value;
	$("flashvarsDIV").innerHTML="<div id='"+curSWFHash+"'></div>";
	if(!createdDefaultFlashVars[curSWFHash])
	{
		var j=0;k=0,cc=0;
		k=defaultFlashVars.length;
		var swfi=swfInfoByHash[curSWFHash];
		if(swfi.customClickTag && swfi.customClickTagValue)
		{
			addFlashVar(swfi.customClickTag,swfi.customClickTagValue)
			cc=swfi.customClickTag;
		}
		for(j;j<k;j++)
		{
			if(defaultFlashVars[j].key==cc) continue;
			addFlashVar(defaultFlashVars[j].key,defaultFlashVars[j].value)
		}
		createdDefaultFlashVars[curSWFHash]=true;
	}
	if(flashvarKeyValueSetsBySWFHash[curSWFHash]&&flashvarKeyValueSetsBySWFHash[curSWFHash].length>0)
	{
		var i=0;l=0;
		var keyID,valueId,keyFieldValue,valueFieldValue,objs;
		l=flashvarKeyValueSetsBySWFHash[curSWFHash].length;
		for(i;i<l;i++)
		{
			objs=flashvarKeyValueSetsBySWFHash[curSWFHash][i];
			keyID=objs.keyID;
			valueID=objs.valueID;
			keyFieldValue=objs.key;
			valueFieldValue=objs.value;
			$(curSWFHash).innerHTML+="<table style='width:100%'><tr><td width='1'><input size='10' type='text' id='"+keyID+"' value='"+keyFieldValue+"'/></td><td>&nbsp;</td><td width='100%'><input type='text' id='"+valueID+"' style='width:100%' value='"+valueFieldValue+"' /></td></tr></table>";
		}
	}
}

function createAllDefaultFlashVars()
{
	var i=0,l=swfInfo.length,swfi,j,k,cc,ccv,hash;
	for(i;i<l;i++)
	{
		swfi=swfInfo[i];
		hash=swfi.hash;
		defaulFlashvarKeyValueSetsBySWFHash[hash]=[]
		if(swfi.customClickTag && swfi.customClickTagValue)
		{
			cc=swfi.customClickTag;
			ccv=swfi.customClickTagValue;
			defaulFlashvarKeyValueSetsBySWFHash[hash].push({key:cc,value:ccv});
		}
		j=0;
		k=defaultFlashVars.length;	
		for(j;j<k;j++)
		{
			if(defaultFlashVars[j].key == cc) continue;
			defaulFlashvarKeyValueSetsBySWFHash[hash].push({key:defaultFlashVars[j].key,value:defaultFlashVars[j].value});
		}
	}
}

function onTemplateChange()
{
	clearswfs();
	stopTimer(true);
}

function clearCurrentFlashVars()
{
	flashvarKeyValueSetsBySWFHash[curSWFHash]=null;
	flashvarObjectIDSBySWFHash[curSWFHash]=null;
	createdDefaultFlashVars[curSWFHash]=false;
	$(curSWFHash).innerHTML="";
}

function addLoadEvent(func)
{
	var oldonload=window.onload;
	if(typeof window.onload!='function')window.onload=func;
	else window.onload=function(){oldonload();func();}
}

function buildSWFInfoByHash()
{
	var i=0,l=swfInfo.length;
	for(i;i<l;i++) swfInfoByHash[swfInfo[i].hash]=swfInfo[i];
}

function addKeyListeners()
{
	//Event.observe(document,'keypress',onKey);
	//Event.observe(document,'click',onDocumentClick);
}

function onDocumentClick(event)
{
	//if(showKeysModal && Event.isLeftClick(event)) hideKeysModal();
	//window.focus();
}

function nextSWF()
{
	selectSWFSTab();
	var list=swfTabSWFList;
	var selectedIndexes=getSelectedIndexesFromMultiSelect(list)
	if(selectedIndexes.length==0) list.options[0].selected=true;
	else
	{
		if(selectedIndexes[0] == list.options.length-1)
		{
			list.options[0].selected=true;
			list.options[ list.options.length-1 ].selected=false;
		}
		else
		{
			list.options[selectedIndexes[selectedIndexes.length-1]+1].selected=true;
			list.options[selectedIndexes[selectedIndexes.length-1]].selected=false;
		}
	}
	embedSWFS();
}

function previousSWF()
{
	selectSWFSTab();
	var list=swfTabSWFList;
	var selectedIndexes=getSelectedIndexesFromMultiSelect(list)
	if(selectedIndexes.length==0) list.options[list.options.length-1].selected=true;
	else
	{
		if(selectedIndexes[0]==0)
		{
			list.options[list.options.length-1].selected=true;
			list.options[0].selected=false;
		}
		else
		{
			list.options[selectedIndexes[selectedIndexes.length-1]-1].selected=true;
			list.options[selectedIndexes[selectedIndexes.length-1]].selected=false;
		}
	}
	embedSWFS();
}

function selectSWFSTab()
{
	qatabs.first();
}

function selectFlashvarsTab()
{
	qatabs.last();
}

function selectFirstSWF()
{
	var list=swfTabSWFList;
	var selectedIndexes=getSelectedIndexesFromMultiSelect(list)
	if(selectedIndexes && selectedIndexes.length>0)
	{
		var i=0,l=selectedIndexes.length;
		for(i;i<l;i++) list.options[selectedIndexes[i]].selected=false;
	}
	list.options[0].selected=true;
	embedSWFS();
}

function hideKeysModal(toggleBool)
{
	if(isPreviewPage)return;
	var m=$("modal");
	m.style.display="none";
	keysModalShown=false;
}
function showKeysModal()
{
	var m = $("modal");
	if(keysModalShown) hideKeysModal();
	else
	{
		keysModalShown=true
		m.style.display="block";
	}
}

function selectLastSWF()
{
	var list=swfTabSWFList;
	var selectedIndexes=getSelectedIndexesFromMultiSelect(list)
	if(selectedIndexes && selectedIndexes.length>0)
	{
		var i=0,l=selectedIndexes.length;
		for(i;i<l;i++) list.options[selectedIndexes[i]].selected=false;
	}
	list.options[list.options.length-1].selected=true;
	embedSWFS();
}

function onKey(event)
{
	return;
	//alert(event.keyCode);
	switch(event.keyCode)
	{
		case 119:
		case 23:
			if(event.metaKey||event.ctrlKey) changeBodyColor("#FFF");
			return false;
			break;
		case 98:
		case 2:
			if(event.metaKey||event.ctrlKey) changeBodyColor("#000");
			break;
		case 99:
		case 3:
			if(event.metaKey||event.ctrlKey) changeBodyColor("#0CF");
			break;
		case 109:
		case 13:
			if(event.metaKey||event.ctrlKey) changeBodyColor("#F06");
			break;
		case 121:
		case 25:
			if(event.metaKey||event.ctrlKey) changeBodyColor("#f0d101")
			break;
		case 103:
		case 7:
			if(event.metaKey||event.ctrlKey) changeBodyColor("#00AC00")
			break;
		case Event.KEY_ESC:
			clearswfs();
			break;
		case Event.KEY_RETURN:
			embedSWFS();
			break;
		case 120:
			embedSWFS();
			break;
		case 107: //k
			showKeysModal();
			break;
		case 49: //1
			selectFirstSWF();
			break;
		case 57: //9
			selectLastSWF();
			break;
		case 112: //p
			previousSWF();
			break;
		case 110: //n
			nextSWF();
			break;
		case 115: //s
			inFlashvarsTab=false;
			selectSWFSTab();
			break;
		case 102: //f
			inFlashvarsTab=true;
			selectFlashvarsTab();
			break;
		
	}
	//if(event.keyCode!=107)hideKeysModal();	
}

function init()
{
	buildSWFInfoByHash();
	addKeyListeners();
	swfTabSWFList=$("swfTabSWFList");
	flashVarSWFList=$("flashVarSWFList");
	if($("previewWrapper")!=null)
	{
		isPreviewPage=true;
		var i=0,l;
		l=swfInfo.length;
		for(i;i<l;i++)
		{
			swf=swfInfo[i];
			$("previewWrapper").innerHTML+="<a class='previewPageLinkF' href='#' onclick=\"embedSWF({},\'"+swf.file+"\',\'"+swf.meta.width+"\',\'"+swf.meta.height+"\',\'"+swf.meta.version+"\',null,true);resetTitle();\">"+ ((swf.previewTitle) ? swf.previewTitle : swf.file)+"</a><br/>";
		}
	}
	else
	{
		addSWFSToSWFTabSWFList();
		addSWFSToFlashvarsSWFList();
		createAllDefaultFlashVars();
		onFlashVarSWFListChange();
	}
	window.onresize=fit;
	fit();
}

function resetTitle()
{
	if(isPreviewPage && Prototype.Browser.IE) document.title="preview";
}

function adjustHeight()
{
	$("wrapper").style.height=document.viewport.getHeight()+"px";
}

function fit()
{
	adjustHeight();
}

function addSWFSToList(selectObj,allFiles)
{
	var list=selectObj;
	var i=0;
	var l=swfInfo.length;
	var option;
	for(i;i<l;i++)
	{
		if(!allFiles && swfInfo[i].type=="bitmap")continue;
		option=document.createElement('option');
		option.text=swfInfo[i].name;
		option.value=swfInfo[i].hash;
		if(Prototype.Browser.IE) list.add(option);
		else list.add(option,null);
	}
}

function addSWFSToSWFTabSWFList()
{
	addSWFSToList(swfTabSWFList,true);
}

function addSWFSToFlashvarsSWFList()
{
	addSWFSToList(flashVarSWFList,false);
}

function canEmbedSWFS()
{
	var list=swfTabSWFList;
	return !(list.selectedIndex==-1);
}

function embedSWFS()
{
	stopTimer();
	resetTimer();
	var list=swfTabSWFList;
	if(list.selectedIndex==-1)
	{
		alert("No swfs are selected");
		return;
	}
	$("embedWrapper").innerHTML="";
	var flashvars,i,l,objs,j,k,si;
	saveCurrentFlashVarData();
	var hashes=getSelectedValuesFromMultiSelect(list);
	var indexes=getSelectedIndexesFromMultiSelect(list);
	var hadSWF=false;
	if(hashes&&hashes.length>0)
	{
		i=0;
		l=hashes.length;
		for(i;i<l;i++)
		{
			si=swfInfo[indexes[i]];
			objs=flashvarKeyValueSetsBySWFHash[hashes[i]]||defaulFlashvarKeyValueSetsBySWFHash[hashes[i]];
			if(objs&&objs.length>0)
			{
				j=0;
				k=objs.length;
				flashvars={};
				for(j;j<k;j++)flashvars[objs[j].key]=objs[j].value;
				if(!si.type || si.type=="swf")
				{
					embedSWF(flashvars,si.file,si.meta.width,si.meta.height,si.meta.version,si.backupBitmap);
					hadSWF=true;
				}
				if(si.type=="bitmap") embedBitmap(si.file)
			}
			else embedSWF({},si.file,si.meta.width,si.meta.height,si.meta.version,si.backupBitmap);
		}
	}
	if(hadSWF)startTimer(true);
}

function embedSWF(vars,swfFile,width,height,version,backupBitmapFile,clearCurrent)
{
	if(clearCurrent)$("embedWrapper").innerHTML="";
	embedVideoCounter++;
	var flashEmbedID="flashwrap"+embedVideoCounter;
	var content = "<table width='100%'><tr><td width='1%'>";
	content+="<div id='"+flashEmbedID+"' class='swf'></div>";
	content+="</td>";
	if($("backupBitmap") && $("backupBitmap").checked)
	{
		if(!backupBitmapFile) content+="<td>&nbsp;</td>";
		else content+="<td><img src='"+backupBitmapFile+"' /></td>";
	}
	else if(backupBitmapFile && $("previewWrapper")!=null) content+="<td><img src='"+backupBitmapFile+"' /></td>";
	content+="</tr></table>";
	$("embedWrapper").innerHTML+=content;
	vars.wmode="transparent"
	var params={wmode:"transparent"};
	var attributes={id:flashEmbedID,name:flashEmbedID};
	swfobject.embedSWF(swfFile,flashEmbedID,width,height,version,null,vars,params,attributes);
}

function embedBitmap(file)
{
	var content="<table width='100%'><tr><td width='1%'>";
	content+="<img src='"+file+"' />"
	content+="</td>";
	$("embedWrapper").innerHTML+=content;
}

function clearswfs()
{
	if(keysModalShown) hideKeysModal();
	stopTimer(true);
	$("embedWrapper").innerHTML="";	
}

function getSelectedValuesFromMultiSelect(selectObject)
{
	var i;
	if(!selectObject)return null;
	var selectedArray=new Array();
  	for(i=0; i<selectObject.options.length;i++)if(selectObject.options[i].selected) selectedArray.push(selectObject.options[i].value);
	return selectedArray;
}

function getSelectedIndexesFromMultiSelect(selectObject)
{
	var i;
	if(!selectObject)return null;
	var selectedArray=new Array();
	for(i=0;i<selectObject.options.length;i++)if(selectObject.options[i].selected)selectedArray.push(i);
	return selectedArray;
}

function changeBodyColor(color)
{
	document.body.style.backgroundColor=color;
}

function resetTimer()
{
	clearTimeout(clocktimer);
	readout='00:00:00.00';
	document.clockform.clock.value=readout;
	$("timerButton").value="start";
	isTiming=false;
}

function toggleTimer()
{
	if(isTiming)stopTimer();
	else startTimer();
}

function startTimer(skipEmbedCall)
{
	if(!canEmbedSWFS())
	{
		alert("No swfs are selected to embed");
		return;
	}
	clearALL();
	isTiming=true;
	findTIME();
	$("timerButton").value="stop";
	if(!skipEmbedCall)embedSWFS();
}

function stopTimer()
{
	isTiming=false;
	clearTimeout(clocktimer);
	$("timerButton").value="start";
}

///////////////////////////////////////////////////////////////
var base=60;
var clocktimer,dateObj,dh,dm,ds,ms;
var readout='';
var h=1;
var m=1;
var tm=1;
var s=0;
var ts=0;
var ms=0;
var show=true;
var init=0;
var mPLUS=new Array('m0','m1','m2','m3','m4','m5','m6','m7','m8','m9');
var ii=0;
function clearALL()
{
	clearTimeout(clocktimer);
	h=1;m=1;tm=1;s=0;ts=0;ms=0;
	init=0;show=true;
	readout='00:00:00.00';
	document.clockform.clock.value=readout;
	var CF=document.clockform;
	ii=0;
}
function startTIME()
{
	var cdateObj=new Date();
	var t=(cdateObj.getTime()-dateObj.getTime())-(s*1000);
	if(t>999){s++;}
	if(s>=(m*base))
	{
		ts=0;
		m++;
	}
	else
	{
		ts=parseInt((ms/100)+s);
		if(ts>=base){ts=ts-((m-1)*base);}
	}
	if(m>(h*base))
	{
		tm=1;
		h++;
	}
	else
	{
		tm=parseInt((ms/100)+m);
		if(tm>=base){tm=tm-((h-1)*base);}
	}
	ms=Math.round(t/10);
	if(ms>99) {ms=0;}
	if(ms==0) {ms='00';}
	if(ms>0&&ms<=9){ms='0'+ms;}
	if(ts>0){ds=ts; if (ts<10){ds='0'+ts; }} else{ds='00';}
	dm=tm-1;
	if(dm>0){if(dm<10){dm='0'+dm;}}else{dm='00';}
	dh=h-1;
	if(dh>0){if(dh<10){dh='0'+dh;}}else{dh='00';}
	readout=dh+':'+dm+':'+ds+'.'+ms;
	if(show==true){document.clockform.clock.value=readout;}
	clocktimer=setTimeout("startTIME()",1);
}
function findTIME()
{
	if(init==0)
	{
		dateObj=new Date();
		startTIME();
		init=1;
	}
	else
	{
		if(show==true)show=false;
		else show=true;
	}
}
function queryStringParamSafeValue(name,caseInsensitive,defaultValueIfNull)
{
	name=name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	var r="[\\?&]"+name+"=([^&#]*)";
	var rmod=""
	if(caseInsensitive)rmod+="i";
	var s=new RegExp(r,rmod);
	var res=s.exec(window.location.href.toString());
	if(!res&&defaultValueIfNull)return defaultValueIfNull;
	else if(!res)return null;
	else return res[1];
}
Math.uuid=(function()
{
  	var CHARS='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('');
  	return function (len,radix)
	{
    	var chars=CHARS,uuid=[],rnd=Math.random;
    	radix=radix||chars.length;
    	if(len)for(var i=0;i<len;i++)uuid[i]=chars[0|rnd()*radix];
		else
		{
      		uuid[8]=uuid[13]=uuid[18]=uuid[23]='-';
      		uuid[14]='4';
      		for(var i=0;i<36;i++)
			{
        		if(!uuid[i])
				{
          			r =0|rnd()*16;
          			uuid[i]=chars[(i==19)?(r&0x3)|0x8:r&0xf];
        		}
      		}
    	}
    	return uuid.join('');
  	};
})();
var randomUUID=Math.uuid;