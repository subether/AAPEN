/**
 * ETHER|AAPEN|WEB - LIB|HELPERS
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

//
// helper functions
//

/**
 * Generates a random MAC address with prefix 52:54:13
 * @returns {string} Random MAC address in format XX:XX:XX:XX:XX:XX
 */
function generate_mac(){
	const prefix = "52:54:13";
	const suffix = "XX:XX:XX".replace(/X/g, () => 
		"0123456789ABCDEF".charAt(Math.floor(Math.random() * 16))
	);
	return `${prefix}:${suffix}`;
}

/**
 * Sorts an array alphabetically
 * @param {Array} list - Array to sort
 * @returns {Array} Sorted array
 */
function sort_alpha(list){
	return [...list].sort((a, b) => a.localeCompare(b));
}

/**
 * Sorts an array numerically
 * @param {Array<number>} list - Array of numbers to sort
 * @returns {Array<number>} Sorted array
 */
function sort_num(list){
	list.sort(function(a, b){ return a - b });
	return list;
}


/**
 * Checks if string contains only alphanumeric characters
 * @param {string} string - String to validate
 * @returns {boolean} True if string is alphanumeric
 */
function string_check_alphanum(string) {
	return /^[0-9a-zA-Z]+$/.test(string);
}

/**
 * Checks if string contains only numeric characters
 * @param {string} string - String to validate
 * @returns {boolean} True if string is numeric
 */
function string_check_num(string) {
	return /^\d+$/.test(string);
}

/**
 * Checks if string contains only valid name characters (alphanumeric, underscore, hyphen)
 * @param {string} string - String to validate
 * @returns {boolean} True if string contains valid name characters
 */
function string_check_name(string) {
	return /^[\w-]+$/.test(string);
}

/**
 * Gets current time in HH:MM:SS format
 * @returns {string} Formatted time string
 */
function date_get_simple(){
	return new Date().toLocaleTimeString('en-GB', {
		hour: '2-digit',
		minute: '2-digit',
		second: '2-digit',
		hour12: false
	});
}

/**
 * Formats bytes into human readable string with appropriate unit
 * @param {number|string} x - Number of bytes to format
 * @param {number} [base=1024] - Base for calculation (1024 for binary, 1000 for decimal)
 * @param {string[]} [units] - Custom units array
 * @returns {string} Formatted string with unit (bytes, KB, MB, etc.)
 */
function formatBytes(x, base = 1024, units = null) {
    const binaryUnits = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const decimalUnits = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    
    const num = typeof x === 'string' ? parseFloat(x) : x;
    const unitSet = units || (base === 1024 ? binaryUnits : decimalUnits);
    
    if(isNaN(num) || num < 0) return '0 bytes';
    if(num === 0) return '0 bytes';

    const exponent = Math.min(
        Math.floor(Math.log(num) / Math.log(base)),
        unitSet.length - 1
    );
    const value = num / Math.pow(base, exponent);
    
    // Format to 1 decimal place for values < 10, otherwise whole numbers
    const formattedValue = value < 10 ? 
        value.toFixed(1).replace(/\.0$/, '') : 
        Math.round(value);
    
    return `${formattedValue} ${unitSet[exponent]}`;
}

/**
 * Formats bytes using binary (base-2) units (1024 bytes = 1KB)
 * @param {number|string} x - Number of bytes
 * @returns {string} Formatted string with unit
 */
function niceBytes(x) {
    return formatBytes(x, 1024);
}

/**
 * Formats megabytes using binary (base-2) units (1024 MB = 1GB)
 * @param {number|string} x - Number of megabytes
 * @returns {string} Formatted string with unit
 */
function niceMBytes(x) {
    return formatBytes(x, 1024, ['MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']);
}

/**
 * Formats gigabytes using binary (base-2) units (1024 GB = 1TB)
 * @param {number|string} x - Number of gigabytes
 * @returns {string} Formatted string with unit
 */
function niceGBytes(x) {
    return formatBytes(x, 1024, ['GB', 'TB', 'PB', 'EB', 'ZB', 'YB']);
}

/**
 * Formats bytes using decimal (base-10) units (1000 bytes = 1KB)
 * @param {number|string} x - Number of bytes
 * @returns {string} Formatted string with unit
 */
function niceBytesMem(x) {
    return formatBytes(x, 1000);
}

/**
 * Formats memory megabytes using base-10 units (1000 MB = 1GB)
 * @param {number} x - Number of megabytes
 * @returns {string} Formatted string with unit
 */
/**
 * Formats memory megabytes using base-10 units (1000 MB = 1GB)
 * @param {number|string} x - Number of megabytes to format
 * @returns {string} Formatted string with appropriate unit (MB, GB, TB, etc.)
 */
function niceMBytesMem(x) {
    const units = ['MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const num = typeof x === 'string' ? parseFloat(x) : x;
    
    if(isNaN(num) || num < 0){
        return '0 MB';
    }

    if(num === 0){
        return '0 MB';
    }

    const exponent = Math.min(
        Math.floor(Math.log10(num) / 3),
        units.length - 1
    );
    const value = num / Math.pow(1000, exponent);
    
    // Format to 1 decimal place for values < 10, otherwise whole numbers
    const formattedValue = value < 10 ? 
        value.toFixed(1).replace(/\.0$/, '') : 
        Math.round(value);
    
    return `${formattedValue} ${units[exponent]}`;
}

/**
 * Normalizes storage unit names (e.g. MiB -> MB)
 * @param {string} unit - Unit to normalize
 * @returns {string} Normalized unit name
 */
/**
 * Normalizes storage unit names to standard base-10 units
 * @param {string} unit - Unit to normalize (case insensitive)
 * @returns {string} Normalized unit (KB, MB, GB, TB) or original if no match
 */
function niceUnits(unit) {
    const unitMap = {
        'kib': 'KB',
        'k': 'KB',
        'mib': 'MB', 
        'm': 'MB',
        'gib': 'GB',
        'g': 'GB',
        'tib': 'TB',
        't': 'TB'
    };
    
    const normalized = unitMap[unit.toLowerCase()];
    return normalized || unit;
}

/**
 * Adds a menu item to a navigation element
 * @param {string} name - Display name
 * @param {string} element - ID of parent UL element
 * @param {string} id - ID for new menu item
 * @param {string} icon - Icon class name
 * @param {function} func - Click handler function
 */
function menu_add_item(name, element, id, icon, func){
	var ul = document.getElementById(element);
	
	var li = document.createElement("li");
	li.setAttribute("id", id);
	li.className = "nav-link nav-link-menu nav-link-btn";
	
	// icon
	var span = document.createElement("i");
	span.setAttribute("class", "bs-icon feather bi " + icon);
	
	// button
	var but = document.createElement("button");
	but.className = "btn btn-sm";
	but.appendChild(span);
	but.innerHTML += name;
	but.value = "name" + name;
	but.id = "name" + name;
	but.style.color = "#D3D3D3";
	but.onclick = func;
	
	li.appendChild(but);
	ul.appendChild(li);	
}

/**
 * Builds a text input element with label
 * @param {string} id - Input element ID
 * @param {string} text - Label text
 * @param {string} placeholder - Input placeholder text
 * @returns {HTMLElement} Created div containing the input
 */
function view_textbox_build(id, text, placeholder){
    return view_textbox_build_advanced(id, text, placeholder);
}

/**
 * Builds a disabled text input element with label
 * @param {string} id - Input element ID
 * @param {string} text - Label text
 * @param {string} placeholder - Input placeholder text
 * @returns {HTMLElement} Created div containing the disabled input
 */
function view_textbox_build_disabled(id, text, placeholder){
    return view_textbox_build_advanced(id, text, placeholder, {disabled: true});
}

/**
 * Builds a text input element with label and advanced options
 * @param {string} id - Input element ID
 * @param {string} text - Label text
 * @param {string} placeholder - Input placeholder text
 * @param {object} [options] - Configuration options
 * @param {boolean} [options.disabled] - Whether to disable the input
 * @param {string} [options.className] - Additional CSS classes for input
 * @returns {HTMLElement} Created div containing the input
 */
function view_textbox_build_advanced(id, text, placeholder, options = {}) {
    var divText = document.createElement("div");
    divText.setAttribute("class", "input-group input-group-sm mb-2 mt-1");
    
    var span = document.createElement("span");
    span.setAttribute("class", "input-group-text");
    span.innerHTML = text;
    
    var input = document.createElement("input");
    input.setAttribute("type", "text");
    input.setAttribute("class", "form-control" + (options.className ? ' ' + options.className : ''));
    input.setAttribute("id", id);
    input.setAttribute("placeholder", placeholder);
    input.value = placeholder;
    
    if(options.disabled){
        input.setAttribute("disabled", "true");
    }
    
    divText.appendChild(span);
    divText.appendChild(input);
    
    return divText;
}

/**
 * Builds a header element with icon
 * @param {string} header - Header text
 * @param {string} icon - Icon class name
 * @returns {HTMLElement} Created header div
 */
function view_header_build(header, icon){
	
	var divRow = document.createElement("div");
	divRow.setAttribute("class", "row row-space pb-1");
	
	var divCol = document.createElement("div");
	divCol.setAttribute("class", "col-lg-11 d-flex align-items-center");
	
	var divIcon = document.createElement("i");
	divIcon.setAttribute("class", "bi " + icon);
	divIcon.setAttribute("style", "font-size: 1.25rem");
	
	var divHeader = document.createElement("div");
	divHeader.setAttribute("class", "ms-2 mt-1");
	
	var divText = document.createElement("div");
	divText.innerHTML = "<h5>" + header + "</h5>";
	
	divHeader.appendChild(divText);
	
	divCol.appendChild(divIcon);
	divCol.appendChild(divHeader);
	
	divRow.appendChild(divCol);
	
	return divRow;
	
}

/**
 * Builds a select dropdown element
 * @param {string} id - Select element ID
 * @param {string} text - Label text
 * @param {string} inputlist - Semicolon-separated options
 * @param {string} selected - Initially selected option
 * @returns {HTMLElement} Created select element container
 */
function view_selector_build(id, text, inputlist, selected){

	var divType = document.createElement("div");
	divType.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var span = document.createElement("span");
	span.setAttribute("class", "input-group-text");
	span.innerHTML = text;
	
	var inputtype = document.createElement("select");
	inputtype.setAttribute("class", "form-select");
	inputtype.setAttribute("id", id);

	var typelist = inputlist.split(';');
	
	typelist.forEach((type) => {
		var option = document.createElement("option");
		option.value = type;
		option.innerHTML = type;
		
		if(type == selected){
			option.selected = true;
		}
		
		inputtype.appendChild(option);
	});
	
	
	divType.appendChild(span);
	divType.appendChild(inputtype);	
	
	return divType;
}


function view_selector_build_array(id, text, inputList, selected){

	var divType = document.createElement("div");
	divType.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var span = document.createElement("span");
	span.setAttribute("class", "input-group-text");
	span.innerHTML = text;
	
	var inputtype = document.createElement("select");
	inputtype.setAttribute("class", "form-select");
	inputtype.setAttribute("id", id);

	//var typelist = inputlist.split(';');
	
	inputList.forEach((type) => {
		var option = document.createElement("option");
		option.value = type;
		option.innerHTML = type;
		
		if(type == selected){
			option.selected = true;
		}
		
		inputtype.appendChild(option);
	});
	
	
	divType.appendChild(span);
	divType.appendChild(inputtype);	
	
	return divType;
}

/**
 * Builds a styled button with icon
 * @param {string} id - Button ID
 * @param {string} icon - Icon class name
 * @param {string} text - Button text
 * @returns {HTMLElement} Created button element
 */
function view_btn_type1_build(id, icon, text){
	
	var btn = document.createElement("button");
	btn.setAttribute("class", "btn btn-sm btn-outline-secondary ms-1");
	
	var btnIcon = document.createElement("i");
	btnIcon.setAttribute("class", "bi " + icon);
	btnIcon.setAttribute("style", "font-size: 1.25rem");
	
	var btnDiv = document.createElement("div");
	btnDiv.setAttribute("class", "ms-1");
	
	var btnText = document.createElement("div");
	btnText.innerHTML = text;
	
	btnDiv.appendChild(btnText);
	btn.appendChild(btnIcon);
	btn.appendChild(btnDiv);	
	
	return btn;
}

/**
 * Builds an accordion header element
 * @param {string} id - Accordion ID
 * @param {string} target - ID of content to expand
 * @param {string} icon - Icon class name
 * @param {string} text - Header text
 * @returns {HTMLElement} Created accordion element
 */
function view_accordion_build(id, target, icon, text){
	
	var accordion = document.createElement("div");
	accordion.setAttribute("class", "accordion-item");
	accordion.setAttribute("id", id);

	// icon
	var span = document.createElement("i");
	span.setAttribute("class", "me-3 bi " + icon);
	
	// button
	var but = document.createElement("button");
	but.setAttribute("class", "accordion-button collapsed");
	but.setAttribute("type", "button");
	but.setAttribute("data-bs-toggle", "collapse");
	but.setAttribute("data-bs-target", "#" + target);
	but.setAttribute("aria-expanded", "false");
	but.setAttribute("aria-controls", "#" + target);
	but.appendChild(span);
	but.innerHTML += text;
	but.id = id + "btn";

	accordion.appendChild(but);	
	
	return accordion;
}

/**
 * Builds an accordion content container
 * @param {string} id - Content element ID
 * @param {string} heading - Header ID this belongs to
 * @param {string} parent - Parent accordion ID
 * @returns {HTMLElement} Created accordion content div
 */
function view_accordion_element_build(id, heading, parent){
	// accordion item
	var div = document.createElement("div");
	div.setAttribute("class", "accordion-collapse collapse");
	div.setAttribute("id", id);
	div.setAttribute("aria-labelledby", heading);
	div.setAttribute("data-bs-parent", "#" + parent);
	
	return div;
}

/**
 * Builds a progress bar with label
 * @param {string} barname - Bar name/title
 * @param {string} bardesc - Description text
 * @param {string} barid - Progress bar element ID
 * @param {number} usedPerc - Percentage value (0-100)
 * @returns {HTMLElement} Created progress bar container
 */
function view_bar_add(barname, bardesc, barid, usedPerc){

	var bar = document.createElement("div");
	bar.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2 me-2");
	
	var colOne = document.createElement("div");
	colOne.setAttribute("class", "col-lg-8 rounded-3 p-2 col-md-offset-2");
	colOne.innerHTML += "[<b> " + barname + " </b>] " + bardesc;
	
	bar.appendChild(colOne);
	
	var sizebardiv = document.createElement("div");
	sizebardiv.setAttribute("class", "progress");
	
	var sizebar = document.createElement("div");
	sizebar.setAttribute("id", barid);
	sizebar.setAttribute("class", "progress-bar");
	sizebar.setAttribute("role", "progressbar");
	sizebar.setAttribute("aria-valuenow", usedPerc);
	sizebar.setAttribute("aria-valuemin", 0);
	sizebar.setAttribute("aria-valuemax", 100);
	
	sizebar.setAttribute("style", "width:" + usedPerc + "%");
	sizebar.innerHTML = usedPerc + "%";
	
	sizebardiv.appendChild(sizebar);
	
	bar.appendChild(sizebardiv);

	return bar;	
}

/**
 * Builds a progress bar with label (no margin bottom variant)
 * @param {string} barname - Bar name/title
 * @param {string} bardesc - Description text
 * @param {string} barid - Progress bar element ID
 * @param {number} usedPerc - Percentage value (0-100)
 * @returns {HTMLElement} Created progress bar container
 */
function view_bar_add_nomb(barname, bardesc, barid, usedPerc){

	var bar = document.createElement("div");
	bar.setAttribute("class", "row row-space g-1 mt-2 ms-2 mb-2 me-2");
	
	var colOne = document.createElement("div");
	colOne.setAttribute("class", "col-lg-8 rounded-3 p-2 col-md-offset-2");
	colOne.innerHTML += "[<b> " + barname + " </b>] " + bardesc;
	
	bar.appendChild(colOne);
	
	var sizebardiv = document.createElement("div");
	sizebardiv.setAttribute("class", "progress");
	
	var sizebar = document.createElement("div");
	sizebar.setAttribute("id", barid);
	sizebar.setAttribute("class", "progress-bar");
	sizebar.setAttribute("role", "progressbar");
	sizebar.setAttribute("aria-valuenow", usedPerc);
	sizebar.setAttribute("aria-valuemin", 0);
	sizebar.setAttribute("aria-valuemax", 100);
	
	sizebar.setAttribute("style", "width:" + usedPerc + "%");
	sizebar.innerHTML = usedPerc + "%";
	
	sizebardiv.appendChild(sizebar);
	
	bar.appendChild(sizebardiv);

	return bar;	
}

/**
 * Initializes a table by clearing its contents
 * @param {string} tableStr - Table ID
 * @returns {jQuery} jQuery object for the table body
 */
function view_table_init(tableStr){
	$("#" + tableStr + " tbody tr").remove();
	return $("#" + tableStr + " tbody");
	//return table;
}

/**
 * Wraps message in green healthy styling
 * @param {string} msg - Message to style
 * @returns {string} HTML string with styling
 */
function view_color_healthy(msg){
	msg = '<b style="color:#24be14">' + msg + '</b>';
	return msg;
}

/**
 * Wraps message in orange warning styling
 * @param {string} msg - Message to style
 * @returns {string} HTML string with styling
 */
function view_color_warning(msg){
	msg = '<b style="color:#F08000">' + msg + '</b>';
	return msg;
}

/**
 * Wraps message in red error styling
 * @param {string} msg - Message to style
 * @returns {string} HTML string with styling
 */
function view_color_error(msg){
	msg = '<b style="color:#FF0000">' + msg + '</b>';
	return msg;
}

/**
 * Styles a boolean value (true=green, false=red)
 * @param {boolean|string} bool - Boolean to style
 * @returns {string} HTML string with styled boolean
 */
function view_color_boolean(bool){
	if(bool == 1 || bool == "1" || bool == "true"){
		return view_color_healthy("true");
	}
	else if(bool = 0 || bool == "0" || bool == "false"){
		return view_color_error("false");
	}
	else{
		return view_color_warning("unknown");
	}

}

/**
 * Styles a boolean value inverted (true=red, false=green)
 * @param {boolean|string} bool - Boolean to style
 * @returns {string} HTML string with styled boolean
 */
function view_color_boolean_inv(bool){
	if(bool == 0 || bool == "0" || bool == "false"){
		return view_color_healthy("false");
	}
	else if(bool == 1 || bool == "1" || bool == "true"){
		return view_color_error("true");
	}
	else{
		return view_color_warning("unknown");
	}
}

/**
 * Styles a status string based on its value
 * @param {string} status - Status to style
 * @returns {string} HTML string with colored status
 */
function view_health_color_status(status){
	status = status.toUpperCase(status);
	
	if(status == "HEALTHY" || status == "ONLINE" || status == "NORMAL" || status == "ACTIVE" || status == "RUNNING" || status == "OK"){
		status = view_color_healthy(status);
	}
	else if(status == "ERROR" || status == "error"){ 
		status = view_color_error(status);
	}
	else{
		status = view_color_warning(status);
	}
	
	return status;
}

/**
 * Styles a status string based on its value
 * @param {string} status - Status to style
 * @returns {string} HTML string with colored status
 */
function view_health_color_temp(temp){
	//status = status.toUpperCase(status);
	
	if(parseInt(temp) < 70){
		status = view_color_healthy(temp);
	}
	else{
		status = view_color_warning(temp);
	}
	
	return status;
}

/**
 * Converts semicolon-delimited string to array
 * @param {string} str - String to convert
 * @returns {Array} Resulting array
 */
function index_to_array(str){
	return str.toString().split(';').filter(Boolean);
}

/**
 * Checks if string contains semicolon
 * @param {string} str - String to check
 * @returns {boolean} True if string contains semicolon
 */
function string_contains(str){
	return str.toString().includes(';');
}

function string_undefined(string){

	if(typeof string !== 'undefined'){
		return string;
	}
	else{
		return "";
	}
	
}

/**
 * Convert date string to Date object
 * @param {string} datestr - Date string in format "DD-MM-YYYY-HH-MM-SS"
 * @returns {Date} Date object
 */
function date_str_to_obj(datestr) {
    if(datestr && datestr.trim() !== ""){
        // Parse the date string
        const parts = datestr.split('-');
        if(parts.length >= 6){
            const day = parseInt(parts[0], 10);
            const month = parseInt(parts[1], 10) - 1; // JavaScript months are 0-indexed
            const year = parseInt(parts[2], 10);
            const hour = parseInt(parts[3], 10);
            const minute = parseInt(parts[4], 10);
            const second = parseInt(parts[5], 10);
            
            // Create and return Date object in UTC
            return new Date(Date.UTC(year, month, day, hour, minute, second));
        }
    }
    
    // Return default date (January 1, 2000) for invalid/empty input (UTC)
    return new Date(Date.UTC(2000, 0, 1, 0, 0, 0));
}

/**
 * Get current date in the same string format
 * @returns {string} Current date as "DD-MM-YYYY-HH-MM-SS"
 */
function date_get() {
    const now = new Date();
    const day = String(now.getUTCDate()).padStart(2, '0');
    const month = String(now.getUTCMonth() + 1).padStart(2, '0'); // Months are 0-indexed
    const year = now.getUTCFullYear();
    const hour = String(now.getUTCHours()).padStart(2, '0');
    const minute = String(now.getUTCMinutes()).padStart(2, '0');
    const second = String(now.getUTCSeconds()).padStart(2, '0');
    
    return `${day}-${month}-${year}-${hour}-${minute}-${second}`;
}

/**
 * Calculate difference in seconds between given date string and now
 * @param {string} datestr - Date string in format "DD-MM-YYYY-HH-MM-SS"
 * @returns {number} Difference in seconds (positive if date is in the past, negative if in the future)
 */
function date_str_diff_now(datestr) {
    const dateObj = date_str_to_obj(datestr);
    const now = new Date();
    
    // Calculate difference in milliseconds and convert to seconds
    const diffMs = now.getTime() - dateObj.getTime();
    return Math.floor(diffMs / 1000);
}
