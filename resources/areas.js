/**
	Open Innovations Leeds line charts in SVG
	Version 0.4.4
  */
!function(t){var e=t.OI||{};function i(t,e){if(!t)return console.error("No element to attach to"),this;var i,h,c,d,u,p,f,g,y,b,k,x,m,w,v,L,M;e||(e={}),d=new function(t){var e=document.createElement("div");return e.classList.add("spinner"),e.setAttribute("style","position:absolute;left:50%;top:50%;transform:translate3d(-50%,-50%,0);"),o(e,t),this.loading=function(){return e.innerHTML="Loading...",this},this.loaded=function(){return e.innerHTML="",this},this.remove=function(){return e&&e.parentNode.removeChild(e),this},this.error=function(t){return e&&(console.error(t),e.innerHTML='<span class="error">ERROR: '+t+"</span>"),this},this}(t).loading(),this.el=t,M="linechart",c="http://www.w3.org/2000/svg",m=e.duration||"0.3s",i=t.clientWidth,h=t.clientHeight;var P=getComputedStyle(t);function A(){var t=s(u,"."+M+"-tooltip");return t&&t.parentNode.removeChild(t),!0}function S(t,e){return{x:t=w.left+(t-f)/(y-f)*(i-w.left-w.right),y:e=w.top+(1-(e-g)/(b-g))*(h-w.bottom-w.top)}}function C(t){return document.createElementNS(c,t)}function N(t,e,s){var c={line:{show:!0,stroke:"black","stroke-width":1,"stroke-linecap":"round","stroke-dasharray":""},grid:{show:!1,stroke:"black","stroke-width":1,"stroke-linecap":"round","stroke-dasharray":""},title:{},ticks:{show:!0},labels:{}};this.ticks={},this.line={},this.el=C("g"),a(this.el,[M+"-grid",M+"-grid-"+t]),this.title=C("text"),this.title.classList.add(M+"-grid-title"),o(this.title,this.el);var d=w["font-size"]||16;return o(this.el,u),this.setProperties=function(t){return r(c,t),this},this.getProperty=function(t){return c.hasOwnProperty(t)?c[t]:null},this.update=function(){var r,a,u,p,k,x,m,v,L;for(r in c.labels||(c.labels={}),this.title.innerHTML=c.title.label||"",a="x"==t?w.left+(i-w.right-w.left)/2:d/2,u="y"==t?w.top+(h-w.top-w.bottom)/2:h-d/2,l(this.title,{x:a,y:u,transform:"y"==t?"rotate(-90,"+a+","+u+")":""}),this.el.removeAttribute("style"),this.line.el||(this.line.el=C("path"),this.line.el.classList.add("line"),this.line.el.setAttribute("vector-effect","non-scaling-stroke"),o(this.line.el,this.el),this.line.animate=new T(this.line.el)),p=[{x:w.left-.5,y:h-w.bottom-.5},{x:"x"==t?i-w.right:w.left-.5,y:"x"==t?h-w.bottom-.5:w.top-.5}],this.line.animate.set({d:{from:"",to:p}}),l(this.line.el,{style:c.line.show?"display:block":"display:none",stroke:c.line.stroke,"stroke-width":c.line["stroke-width"],"stroke-dasharray":c.line["stroke-dasharray"]}),this.ticks)r&&!c.ticks.show&&(this.ticks[r].line&&this.ticks[r].line.parentNode.removeChild(this.ticks[r].line),this.ticks[r].text&&this.ticks[r].text.parentNode.removeChild(this.ticks[r].text),delete this.ticks[r]);for(r in c.labels)void 0!==r&&(x=c.labels[r].align||("x"==t?"bottom":"left"),m=c.labels[r]["text-anchor"]||("y"==t?"left"==x?"end":"start":"middle"),k="number"==typeof c.labels[r].length?c.labels[r].length:5,a="x"==t?parseFloat(r):"left"==x?f:y,u="x"==t?"bottom"==x?g:b:parseFloat(r),(e=S(a,u)).x=Math.round(e.x),s.x=Math.round(s.x),s=n(e),"x"==t?(c.grid.show&&a!=f&&(e.y="bottom"==x?w.top:h-w.bottom),s.y+="bottom"==x?k:-k):(c.grid.show&&u!=g&&(e.x="left"==x?i-w.right:w.left),s.x+="left"==x?-k:k),"x"==t&&(a<f||a>y)||"y"==t&&(u<g||u>b)?this.ticks[r]&&(this.ticks[r].line&&this.ticks[r].line.el.setAttribute("style","display:none"),this.ticks[r].text&&this.ticks[r].text.el.setAttribute("style","display:none")):(this.ticks[r]?(this.ticks[r].line&&this.ticks[r].line.el.removeAttribute("style"),this.ticks[r].text.el.removeAttribute("style")):(this.ticks[r]={text:{el:C("text")}},k>0&&(this.ticks[r].line={el:C("line")},this.ticks[r].line.animate=new T(this.ticks[r].line.el),o(this.ticks[r].line.el,this.el)),this.ticks[r].text.animate=new T(this.ticks[r].text.el),this.ticks[r].text.el.setAttribute("text-anchor",c["text-anchor"]||m),o(this.ticks[r].text.el,this.el)),this.ticks[r].line&&(this.ticks[r].line.animate.set({x1:{to:e.x-.5},x2:{to:s.x-.5},y1:{to:e.y-.5},y2:{to:s.y-.5}}),l(this.ticks[r].line.el,{stroke:c.grid.stroke,"stroke-width":c.grid["stroke-width"]})),this.ticks[r].text.el.innerHTML=c.labels[r].label,l(this.ticks[r].text.el,{stroke:c.labels[r].stroke||"black","stroke-width":c.labels[r]["stroke-width"]||0,fill:c.labels[r].fill||"black"}),v=s.x+(c.labels[r].dx||0)+("y"==t?4*("right"==c.labels[r].align?1:-1):0),L=s.y+(c.labels[r].dy||0)+("x"==t?4*("bottom"==c.labels[r].align?-1:1):0),this.ticks[r].text.animate.set({x:{to:v},y:{to:L}})));o(this.line.el,this.el)},this}function E(e,i,h){var c,d,p,k,x;function m(e){var r=parseInt(e.target.getAttribute("data-i"));i[r]?function(e,i,r,n,l){var h,c,d,p,f;if(L)(c=s(L,"."+M+"-tooltip"))||(a(c=document.createElement("div"),[M+"-tooltip"]),o(c,L)),h=s(e,"title").innerHTML,n.label||(n.label=h),"function"==typeof l.label?h=l.label.call(e,{series:i,i:r,data:n}):"string"==typeof l.label&&(h=l.label),h=h.replace(/\n/g,"<br />"),c.innerHTML=h,d="","function"==typeof l.class?d=l.class.call(e,{series:i,i:r,data:n}):"string"==typeof l.class&&(d=l.class),d&&c.setAttribute("class",d),p=e.getBoundingClientRect(),f=u.getBoundingClientRect(),c.setAttribute("style","position:absolute;left:"+Math.round(p.left+p.width/2-f.left+t.scrollLeft)+"px;top:"+Math.round(p.top+p.height/2-f.top)+"px;transform:translate3d(-50%,-100%,0);display:"+(h?"block":"none")),o(L,u)}(e.target,c,r,i[r],c.tooltip):console.error("Bad tooltip "+r,e)}return i||(i=[]),c={points:{show:!0,color:"black","stroke-linecap":"round",stroke:"black","stroke-width":0,"fill-opacity":1},line:{show:!0,color:"#000000","stroke-width":4,"stroke-linecap":"round","stroke-linejoin":"round","stroke-dasharray":"",fill:"none"}},d={},p="",k=[],this.el=C("g"),(x={id:c.id||"series-"+(e+1)})[M+"-series"]=e+1,l(this.el,x),a(this.el,[M+"-series",M+"-series-"+(e+1)]),this.select=function(){return d.el.classList.add("on"),this},this.deselect=function(){return d.el.classList.remove("on"),this},this.setData=function(t){return i=t||[],this},this.updateRange=function(){for(var t=0;t<i.length;t++)f=Math.min(f,i[t].x),g=Math.min(g,i[t].y),y=Math.max(y,i[t].x),b=Math.max(b,i[t].y);return this},this.getStyle=function(t,e){return c.hasOwnProperty(t)&&c[t].hasOwnProperty(e)?c[t][e]:null},this.getProperty=function(t){return c.hasOwnProperty(t)?c[t]:null},this.getProperties=function(){return c},this.setProperties=function(t){if(t||(t={}),r(c,t),c.class){var e=c.class.split(/ /);a(this.el,e)}return this},this.update=function(){var t,r,s,a,h,u,f,g;if(d.el||(d.el=C("path"),d.el.classList.add("line"),l(d.el,{d:"M0 0 L 100,100",stroke:c.line.color||"black"}),o(d.el,this.el),d.animate=new T(d.el),d.el.addEventListener("click",O)),l(d.el,{style:c.line.show?"display:block":"display:none",stroke:c.line.color||"black","stroke-width":this.getStyle("line","stroke-width"),"stroke-linecap":this.getStyle("line","stroke-linecap"),"stroke-linejoin":this.getStyle("line","stroke-linejoin"),"stroke-dasharray":this.getStyle("line","stroke-dasharray"),fill:this.getStyle("line","fill"),"vector-effect":"non-scaling-stroke"}),k.length>i.length)for(t=k.length-1;t>=i.length;t--)k[t].el.remove(),k.pop();if(k.length<i.length)for(r=k.length;r<i.length;r++)s=C("circle"),(g={cx:0,cy:0,"data-i":r,tabindex:0})[M+"-series"]=e+1,l(s,g),k[r]={el:s,title:C("title"),old:{}},i[r].label||(i[r].label="Point "+(r+1)),c.tooltip||(c.tooltip={}),a=i[r].label+": "+i[r].y.toFixed(2),"function"==typeof c.tooltip.label?a=c.tooltip.label.call(s,{series:c,i:r,data:i[r]}):"string"==typeof c.tooltip.label&&(a=c.tooltip.label),k[r].title.innerHTML=a,o(k[r].title,s),c.tooltip.label&&(s.addEventListener("mouseover",function(t){t.target.focus()}),s.addEventListener("focus",m)),o(s,this.el),k[r].cx=new T(k[r].el),k[r].cy=new T(k[r].el);for(h=[],r=0;r<k.length;r++)u=(c["stroke-width"]||1)/2,c.points&&("number"==typeof c.points.size&&(u=Math.max(c.points.size,u)),"function"==typeof c.points.size&&(u=c.points.size.call(s,{series:e,i:r,data:i[r]}))),l(k[r].el,{r:u,fill:c.points.color,"fill-opacity":c.points["fill-opacity"],stroke:c.points.stroke,"stroke-width":c.points["stroke-width"]}),f=S(i[r].x,i[r].y),h.push(f),k[r].cx.set({cx:{from:k[r].old.x||null,to:f.x}}),k[r].cy.set({cy:{from:k[r].old.y||null,to:f.y}}),k[r].old=f;return d.animate.set({d:{from:p,to:h}}),p=n(h),this},this.setData(i),this.setProperties(h),o(this.el,u),this}function T(e,i){var r,s,a;return r=window.getComputedStyle(t),s=e.tagName.toLowerCase(),i||(i={}),a={},"0s"!=r["animation-duration"]&&(this.duration=r["animation-duration"]),i.duration&&(this.duration=i.duration),this.duration||(this.duration=m),this.set=function(t){var i,r,h,c,d,u;for(i in e.querySelectorAll("animate").forEach(function(t){t.parentNode.removeChild(t)}),t)if(i){if(d=t[i].from||"",u=t[i].to,!d&&a[i]&&(d=a[i].value),h=null,c=null,"path"==s){for(h="",c="",r=0;r<d.length;r++)h+=(r>0?"L":"M")+d[r].x.toFixed(2)+","+d[r].y.toFixed(2);for(r=0;r<u.length;r++)c+=(r>0?"L":"M")+u[r].x.toFixed(2)+","+u[r].y.toFixed(2);h||(h=null)}else d&&(h=n(d)),c=n(u);this.duration&&null!==h&&(a[i]||(a[i]={}),a[i].el=C("animate"),l(a[i].el,{attributeName:i,dur:this.duration||0,repeatCount:"1"}),o(a[i].el,e)),e.setAttribute(i,c),this.duration&&null!==h&&(l(a[i].el,{from:h,to:c,values:h+";"+c}),a[i].el.beginElement(),a[i].value=u)}return this},this}function H(){f=1e100,g=1e100,y=-1e100,b=-1e100;for(var t=0;t<p.length;t++)p[t].updateRange();"number"==typeof v.x.getProperty("min")&&(f=v.x.getProperty("min")),"number"==typeof v.x.getProperty("max")&&(y=v.x.getProperty("max")),"number"==typeof v.y.getProperty("min")&&(g=v.y.getProperty("min")),"number"==typeof v.y.getProperty("max")&&(b=v.y.getProperty("max"))}function O(t){for(var e=parseInt(t.currentTarget.closest("g").getAttribute(M+"-series"))-1,i=0;i<p.length;i++)e==i?p[i].select():p[i].deselect();o(p[e].el,p[e].el.closest("svg")),x&&o(x.el,x.el.closest("svg")),s(t.target.parentNode,"circle").focus(),o(L,u)}return h-=parseFloat(P.paddingTop)+parseFloat(P.paddingBottom),i-=parseFloat(P.paddingLeft)+parseFloat(P.paddingRight),p=[],r(w={left:0,top:0,right:0,bottom:0,tick:5,"font-size":16,tooltip:{},key:{show:!1,border:{stroke:"black","stroke-width":1,fill:"none"},text:{"text-anchor":"start","dominant-baseline":"hanging","font-weight":"bold",fill:"black","stroke-width":0,"font-family":"sans-serif"}},axis:{x:{},y:{}}},e),u||(l(u=C("svg"),{xmlns:c,version:"1.1",width:i,height:h,viewBox:"0 0 "+i+" "+h,overflow:"visible",style:"max-width:100%;",preserveAspectRatio:"xMinYMin meet"}),o(k=C("defs"),u),o(u,t),t.addEventListener("mouseleave",function(t){A()}),l(L=C("foreignObject"),{width:1,height:1,overflow:"visible"}),o(L,u)),(v={x:new N("x",w.left,i-w.right-w.left),y:new N("y",w.bottom,h-w.top-w.bottom)}).x.setProperties(w.axis.x||{}),v.y.setProperties(w.axis.y||{}),this.getSVG=function(){return u.querySelectorAll("animate").forEach(function(t){t.parentNode.removeChild(t)}),u.outerHTML},this.setProperties=function(t){return r(w,t||{}),this},this.addSeries=function(t,e){return t?(e||(e={}),p.push(new E(p.length,t,e)),H(),this.series=p,this):(d.error("No data in series"),this)},this.draw=function(){var t,e,r,n,h,c,d,f,g,y,b,L,P,S;for(A(),H(),v.x.update(),v.y.update(),t="<style>",t+="\t."+M+"-series circle { transition: transform "+m+" linear, r "+m+" linear; }\n",t+="\t."+M+"-series circle:focus { stroke-width: 4; }\n",t+="\t."+M+"-series:hover path.line, ."+M+"-series.on path.line { cursor:pointer; }\n",e=0;e<p.length;e++)p[e].update(),t+="\t."+M+"-series-"+(e+1)+":hover path.line, ."+M+"-series-"+(e+1)+".on path.line { stroke-width: "+(p[e].getProperty("stroke-width-hover")||4)+"; }\n";if(w.key.show){if(r=w["font-size"]||16,n=w.key.padding||5,h=(w.key.label?1:0)*r+2*n+p.length*r,d=0,f=0,!x){if((x={el:C("g"),g:[],border:C("rect")}).el.classList.add("key"),l(x.border,{x:0,y:w.top,width:i,height:h}),"object"==typeof w.key.border)for(P in w.key.border)x.border.setAttribute(P,w.key.border[P]);o(x.border,x.el),o(x.el,u)}for(c=0,g=0;g<p.length;g++)x.g[g]||(x.g[g]=C("g"),x.g[g].setAttribute(M+"-series",g),S=[M+"-series",M+"-series-"+(g+1)],p[g].getProperty("class")&&S.concat(p[g].getProperty("class").split(/ /)),a(x.g[g],S),o(x.g[g],x.el),x.g[g].addEventListener("mouseover",O)),x.g[g].innerHTML='<text><tspan dx="'+2*r+'" dy="0">'+(p[g].getProperty("title")||"Series "+(g+1))+'</tspan></text><path d="M0 0 L 1 0" class="line" class="" stroke-width="3" stroke-linecap="round"></path><circle cx="0" cy="0" r="5" fill="silver"></circle>',c=Math.max(c,x.g[g].getBoundingClientRect().width);for(d=i-w.right-c-n,f=w.top,l(x.border,{x:d,width:c+n}),f+=n,d+=n,g=0;g<p.length;g++){if(y=s(x.g[g],"text"),b=s(x.g[g],"path"),L=s(x.g[g],"circle"),y.setAttribute("x",d),y.setAttribute("y",f+g*r+.2*r),"object"==typeof w.key.text)for(P in w.key.text)y.setAttribute(P,w.key.text[P]);b.setAttribute("d","M"+d+","+(f+(.5+g)*r)+" l "+1.5*r+" 0"),l(L,{cx:d+.75*r,cy:f+(.5+g)*r,fill:(P=p[g].getProperties()).points.color||"","stroke-width":P.points["stroke-width"]||0,stroke:P.points.stroke||""}),P.line.color&&b.setAttribute("stroke",P.line.color)}}return t+="\t."+M+"-grid."+M+"-grid-x ."+M+"-grid-title,."+M+"-grid."+M+"-grid-y ."+M+"-grid-title { text-anchor: middle; dominant-baseline: central; }\n",t+="\t."+M+"-grid."+M+"-grid-x text { dominant-baseline: hanging; }\n",t+="\t."+M+"-grid."+M+"-grid-y text { dominant-baseline: "+(w.axis.y.labels.baseline||"middle")+"; }\n",t+="\t."+M+"-tooltip { background: black; color: white; padding: 0.25em 0.5em; margin-top: -1em; transition: left 0.1s linear, top 0.1s linear; border-radius: 4px; white-space: nowrap; }\n",t+="\t."+M+'-tooltip::after { content: ""; position: absolute; bottom: auto; width: 0; height: 0; border: 0.5em solid transparent; left: 50%; top: 100%; transform: translate3d(-50%,0,0); border-color: transparent; border-top-color: black; }\n',t+="\t</style>\n",k&&(k.innerHTML=t),this},d.remove(),this}function r(t,e){for(var i in e)try{e[i].constructor==Object?t[i]=r(t[i],e[i]):t[i]=e[i]}catch(r){t[i]=e[i]}return t}function s(t,e){return t.querySelector(e)}function o(t,e){return e.appendChild(t)}function n(t){return JSON.parse(JSON.stringify(t))}function l(t,e){for(var i in e)t.setAttribute(i,e[i]);return t}function a(t,e){for(var i=0;i<e.length;i++)t.classList.add(e[i]);return t}e.ready||(e.ready=function(t){"loading"!=document.readyState?t():document.addEventListener("DOMContentLoaded",t)}),e.linechart=function(t,e){return new i(t,e)},t.OI=e}(window||this);

(function(root){
	// Part of the Open Innovations namespace
	var OI = root.OI || {};
	if(!OI.ready){
		OI.ready = function(fn){
			// Version 1.1
			if(document.readyState != 'loading') fn();
			else document.addEventListener('DOMContentLoaded', fn);
		};
	}

	function defaultSpacing(mn,mx,n){

		var dv,log10_dv,base,frac,options,distance,imin,tmin,i;
	
		// Start off by finding the exact spacing
		dv = (mx-mn)/n;

		// In any given order of magnitude interval, we allow the spacing to be
		// 1, 2, 5, or 10 (since all divide 10 evenly). We start off by finding the
		// log of the spacing value, then splitting this into the integer and
		// fractional part (note that for negative values, we consider the base to
		// be the next value 'down' where down is more negative, so -3.6 would be
		// split into -4 and 0.4).
		log10_dv = Math.log10(dv);
		base = Math.floor(log10_dv);
		frac = log10_dv - base;

		// We now want to check whether frac falls closest to 1, 2, 5, or 10 (in log
		// space). There are more efficient ways of doing this but this is just for clarity.
		options = [1,2,5,10];
		distance = new Array(options.length);
		imin = -1;
		tmin = 1e100;
		for(i = 0; i < options.length; i++){
			distance[i] = Math.abs(frac - Math.log10(options[i]));
			if(distance[i] < tmin){
				tmin = distance[i];
				imin = i;
			}
		}

		// Now determine the actual spacing
		return Math.pow(10,base)*options[imin];
	}
	OI.ready(function(){
		var tables = document.querySelectorAll('.emissions li table');
		tables.forEach(function(t){
			var tr,typ,r,d,td,tm,tabbed,graphs,y,gap,gapstr,prec,monthNames,smonth,m;

			tr = t.querySelectorAll('tr');
			tr.forEach(function(row){
				row.addEventListener('mouseover',function(e){
				});
			});
			if(tr.length > 3){

				tabbed = document.createElement('div');
				tabbed.classList.add('panes');
				tabbed.classList.add('tabbed');
				t.insertAdjacentElement('beforebegin', tabbed);
				tabbed.innerHTML = '<div class="pane"><span class="tab-title">CO2 estimate</span><div class="graph" id="graph-carbon"></div><div class="warning" style="padding:0.25em 0.5em;line-height: 1em;"><span class="small">Note: we used version 2 of the methodology for estimating CO2 emissions until November 2022, <a href=\"https://sustainablewebdesign.org/calculating-digital-emissions/\">version 3</a> until August 2025, and will be using <a href=\"https://sustainablewebdesign.org/estimating-digital-emissions/\">version 4</a> from September 2025. CO2 estimates have reduced with each update to the methodology because the internet appears to be operating more efficiently over time.</span></div></div><div class="pane"><span class="tab-title">Page size</span><div class="graph" id="graph-size"></div></div>';

				graphs = {
					'carbon': new Graph(document.getElementById('graph-carbon'),tr,{
						'column': 1,
						'title': 'CO2 / grams',
						'tooltip': function(d,opt){ return d.data.label+':\n'+d.data.y.toFixed(2)+' grams of CO2'; }
					}),
					'size': new Graph(document.getElementById('graph-size'),tr,{
						'column': 3,
						'scale': 1e-6,
						'title': 'Size / MB',
						'tooltip': function(d,opt){ return d.data.label+':\n'+d.data.y.toFixed(1)+'MB'; }
					})
				}

				OI.TabbedInterface(tabbed);

			}
		});
	});
	function Graph(el,tr,opt){
		if(!el){
			console.error('No element to attach to');
			return this;
		}
		if(!opt) opt = {};
		if(typeof opt.sdate!=="number") opt.sdate = 0;
		if(typeof opt.edate!=="number") opt.edate = 0;
		if(typeof opt.min!=="number") opt.min = 0;
		if(typeof opt.max!=="number") opt.max = -Infinity;
		var r,td,d,tm,data=[],xlabels={},ylabels={};
		for(r = 1; r < tr.length; r++){
			td = tr[r].querySelectorAll('td');
			d = new Date(td[0].innerHTML);
			tm = d.getTime();
			if(r==1) opt.edate = d;
			if(r==tr.length-1) opt.sdate = d;
			y = parseFloat(td[opt.column].getAttribute('data')||td[opt.column].innerText);
			if(typeof opt.scale==="number") y *= opt.scale;
			if(!isNaN(y)){
				opt.max = Math.max(opt.max,y);
				data.unshift({x:tm,y:y,'label':d.toLocaleString('en-GB',{ year: 'numeric', month: 'long', day: 'numeric' })});
			}
		}
		// Build y-axis labels
		gap = defaultSpacing(opt.min,opt.max,3);
		// Work out precision of the gap and limit our labels to the same precision
		gapstr = gap+"";
		prec = (gapstr.indexOf(".") > 0 ? gapstr.split('.')[1].length : 0);
		for(y = opt.min; y <= opt.max; y+=gap) ylabels[y] = {'label':(prec > 0 ? y.toPrecision(prec) : y)};

		// Build x-axis labels
		monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
		for(d = opt.sdate; d <= opt.edate; d.setDate(d.getDate() + 1)){
			smonth = (new Date(d.getFullYear(),d.getMonth(),1)).getTime();
			m = d.getMonth();
			if(!xlabels[smonth]) xlabels[smonth] = {'label':(m==0 ? '' : (m%3==0 ? monthNames[m].substr(0,0) : ""))+(m==0 ? ' '+d.getFullYear():'')};
		}
		this.graph = OI.linechart(el,{
			'left':50,
			'right':10,
			'top':10,
			'bottom':30,
			'axis':{
				'x':{
					'labels':xlabels
				},
				'y':{
					'title':{ 'label':opt.title },
					'grid': {'show':true,'stroke':'#bbb'},
					'min': 0,
					'labels':ylabels
				}
			}
		});
		var _obj = this;
		this.graph.addSeries(data,{
			'points':{'color':'#1DD3A7','size': 4},
			'line':{'color':'#1DD3A7'},
			'tooltip':{
				'label': (typeof opt.tooltip==="function" ? opt.tooltip : function(d){ return d.data.label+':\n'+d.data.y; })
			}
		});
		this.graph.draw();
		return this;
	}

	function TabbedInterface(el){
		var tabs,panes,p,h,b,l;
		this.selectTab = function(t,focusIt){
			var tab,pane;
			tab = tabs[t].tab;
			pane = tabs[t].pane;

			// Remove existing selection and set all tabindex values to -1
			tab.parentNode.querySelectorAll('button').forEach(function(el){ el.removeAttribute('aria-selected'); el.setAttribute('tabindex',-1); });

			// Update the selected tab
			tab.setAttribute('aria-selected','true');
			tab.setAttribute('tabindex',0);
			if(focusIt) tab.focus();

			pane.closest('.panes').querySelectorAll('.pane').forEach(function(el){ el.style.display = "none"; el.setAttribute('hidden',true); });
			pane.style.display = "";
			pane.removeAttribute('hidden');
			// Loop over any potentially visible leaflet maps that haven't been sized and set the bounds
			if(OI.maps){
				for(var m = 0; m < OI.maps.length; m++){
					if(OI.maps[m].map._container==pane.querySelector('.leaflet')){
						OI.maps[m].map.invalidateSize(true);
						if(!OI.maps[m].set){
							if(OI.maps[m].bounds) OI.maps[m].map.fitBounds(OI.maps[m].bounds);
							OI.maps[m].set = true;
						}
					}
				}
			}
			return this;
		};
		this.enableTab = function(tab,t){
			var _obj = this;

			// Set the tabindex of the tab panel
			panes[t].setAttribute('tabindex',0);

			// Add a click/focus event
			tab.addEventListener('click',function(e){ e.preventDefault(); var t = parseInt((e.target.tagName.toUpperCase()==="BUTTON" ? e.target : e.target.closest('button')).getAttribute('data-tab')); _obj.selectTab(t,true); });
			tab.addEventListener('focus',function(e){ e.preventDefault(); var t = parseInt(e.target.getAttribute('data-tab')); _obj.selectTab(t,true); });

			// Store the tab number in the tab (for use in the keydown event)
			tab.setAttribute('data-tab',t);

			// Add keyboard navigation to arrow keys following https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/Tab_Role
			tab.addEventListener('keydown',function(e){

				// Get the tab number from the attribute we set
				t = parseInt(e.target.getAttribute('data-tab'));

				if(e.keyCode === 39 || e.keyCode === 40){
					e.preventDefault();
					// Move right or down
					t++;
					if(t >= tabs.length) t = 0;
					_obj.selectTab(t,true);
				}else if(e.keyCode === 37 || e.keyCode === 38){
					e.preventDefault();
					// Move left or up
					t--;
					if(t < 0) t = tabs.length-1;
					_obj.selectTab(t,true);
				}
			});
		};
		tabs = [];

		l = document.createElement('div');
		l.classList.add('grid','tabs');
		l.setAttribute('role','tablist');
		l.setAttribute('aria-label','Visualisations');
		panes = el.querySelectorAll('.pane');
		for(p = 0; p < panes.length; p++){
			h = panes[p].querySelector('.tab-title');
			b = document.createElement('button');
			b.classList.add('tab');
			b.setAttribute('role','tab');
			if(h) b.appendChild(h);
			l.appendChild(b);
			tabs[p] = {'tab':b,'pane':panes[p]};
			this.enableTab(b,p);
		}
		el.insertAdjacentElement('beforebegin', l);
		this.selectTab(0);

		return this;
	}
	root.OI = OI;
	root.OI.TabbedInterface = function(el){ return new TabbedInterface(el); };
})(window || this);

