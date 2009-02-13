if(typeof(Prototype) == "undefined") throw "HotKey requires Prototype to be loaded.";
if(typeof(Object.Event) == "undefined") throw "HotKey requires Object.Event to be loaded.";
var HotKey = Class.create({
	initialize:function(letter,callback,options)
	{
		letter = letter.toUpperCase();
		HotKey.hotkeys.push(this);
	    this.options=Object.extend(
		{
	      element:false,
	      shiftKey:false,
	      altKey:false,
	      ctrlKey:true,
		  metaKey:false,
	    },options||{});
		this.letter=letter;
	    this.callback=callback;
		this.element=$(this.options.element||document);
    	this.handler = function(event)
		{
			if(!event||
				((Event['KEY_' + this.letter] || this.letter.charCodeAt(0)) == event.keyCode &&
        		((!this.options.shiftKey || (this.options.shiftKey && event.shiftKey)) &&
          		(!this.options.altKey || (this.options.altKey && event.altKey)) &&
          		(!this.options.ctrlKey || (this.options.ctrlKey && event.ctrlKey)) &&
				(!this.options.metaKey || (this.options.metaKey && event.metaKey))
        	)))
			{
        		if(this.notify('beforeCallback',event) === false) return;
        		this.callback(event);
        		this.notify('afterCallback',event);
      		}
		}.bind(this);
    	this.enable();
  	},
  	trigger:function(){
    	this.handler();
  	},
  	enable:function(){
    	this.element.observe('keydown',this.handler);
  	},
  	disable:function(){
    	this.element.stopObserving('keydown',this.handler);
  	},
  	destroy:function(){
    	this.disable();
    	HotKey.hotkeys=Control.HotKey.hotkeys.without(this);
  	}
});
Object.extend(HotKey,{
	hotkeys:[]
});
Object.Event.extend(HotKey);