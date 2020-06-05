//##############################################################################
//# piechart.js                                                                #
//##############################################################################
//# YaBB: Yet another Bulletin Board                                           #
//# Open-Source Community Software for Webmasters                              #
//# Version:        YaBB 2.6.11                                                #
//# Packaged:       December 2, 2014                                           #
//# Distributed by: http://www.yabbforum.com                                   #
//# ===========================================================================#
//# Copyright (c) 2000-2014 YaBB (www.yabbforum.com) - All Rights Reserved.    #
//# Software by:  The YaBB Development Team                                    #
//#               with assistance from the YaBB community.                     #
//##############################################################################

//YaBB 2.6.11 $Revision: 1611 $

function pieChart() {
    this.pie_array = new Array();
    this.radius = 100;
    this.start_angle = 90;
    this.canvas_width = 660;
    this.color_style = '#000000';
    this.use_legends = 0;

    var htm = '';
    var color = '#000000';
    var slice_color = new Array();

    var itohex = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"];

    function tohex(i) {
        a2 = ''
        ihex = Math.floor(eval(i +'/16'));
        idiff = eval(i + '-(' + ihex + '*16)')
        a2 = itohex[idiff] + a2;
        while( ihex >= 16) {
            itmp = Math.floor(eval(ihex +'/16'));
            idiff = eval(ihex + '-(' + itmp + '*16)');
            a2 = itohex[idiff] + a2;
            ihex = itmp;
        }
        a1 = itohex[ihex];
        return a1 + a2 ;
    }

    for (var tz = 0; tz < 256; tz += 63)
        for (var ty = 0; ty < 256; ty += 85)
            for (var tx = 0; tx < 256; tx += 127) slice_color.push('#' + tohex(tx) + tohex(ty) + tohex(tz));

    this.sliceAdd = function() {
        if (this.pie_array.length < 1) return;
        var label_radius = this.radius + 20;
        if(this.use_legends == 1) {
            var canvas_height = (this.radius * 2) + 40;
            var centerx = label_radius;
            var label_width = this.canvas_width - (label_radius * 2);
            var leg_value = new Array();
            var leg_label = new Array();
            var leg_color = new Array();
            for(var i = 0; i < this.pie_array.length; i++) {
                leg_vallabel = this.pie_array[i].split("|");
                if(leg_vallabel[0] > 0) {
                    leg_value.push(parseInt(leg_vallabel[0],10));
                    leg_label.push(leg_vallabel[1]);
                    leg_color.push(leg_vallabel[2]);
                }
            }
            var legends_top = canvas_height - (leg_label.length * 16);
        }
        else {
            var canvas_height = (this.radius * 2) + 80;
            var centerx = this.canvas_width / 2;
            var label_width = (this.canvas_width - (label_radius * 2)) / 2;
        }
        var centery = (canvas_height / 2) - 5;
        var value = new Array();
        var label = new Array();
        var slicecolor = new Array();
        var slicesplit = new Array();
        var angle, ang_rads;
        var votes_tot = 0;
        this.pie_array.reverse();
        for(var i = 0; i < this.pie_array.length; i++) {
            val_label = this.pie_array[i].split("|");
            if(val_label[0] > 0) {
                value.push(parseInt(val_label[0],10));
                votes_tot += parseInt(val_label[0],10);
                label.push(val_label[1]);
                slicecolor.push(val_label[2]);
                slicesplit.push(val_label[3]);
            }
        }
        htm += '<div style="position: relative; top: 0px; left: 0px; margin-left:auto; margin-right:auto; height: ' + canvas_height + 'px; width: ' + this.canvas_width + 'px;">';
        for(var i = 0; i < value.length; i++) {
            angle = Math.round(value[i] / votes_tot * 360);
            if(!slicecolor[i]) slicecolor[i] = slice_color[i+1];
            color = slicecolor[i];
            var z, y, y1, y2, x1, x2, z1, z2, ints, w;
            var actcentery = centery;
            var actcenterx = centerx;
            if(slicesplit[i] == 1) {
                splitang_rads = (this.start_angle + (angle / 2)) * 2 * Math.PI / 360;
                var move_top = (Math.sin(splitang_rads) * 10);
                var move_left = (Math.cos(splitang_rads) * 10);
                actcentery = centery - move_top;
                actcenterx = centerx + move_left;
            }
            var end_angle = this.start_angle + angle;
            var number_of_steps = end_angle - this.start_angle;
            if(number_of_steps < 181.0) number_of_steps = 181.0;
            var angle_increment = 2 * Math.PI / number_of_steps;
            var xarray = new Array();
            var yarray = new Array();
            var start_rads = this.start_angle * Math.PI / 180;
            var end_rads = end_angle * Math.PI / 180;
            for (sl_angle = start_rads; sl_angle <= end_rads; sl_angle += angle_increment) {
                if(end_rads < sl_angle + angle_increment) sl_angle = end_rads;
                y2 = Math.sin(sl_angle) * this.radius;
                x2 = Math.cos(sl_angle) * this.radius;
                xarray.push(actcenterx + x2);
                yarray.push(actcentery - y2);
            }
            xarray.push(actcenterx);
            yarray.push(actcentery);
            var miny = yarray[0];
            var maxy = yarray[0];
            for (z = 1; z < xarray.length; z++) {
                if (yarray[z] < miny) miny = yarray[z];
                if (yarray[z] > maxy) maxy = yarray[z];
            }
            for (y = miny; y <= maxy; y++) {
                var sliceInts = new Array();
                ints = 0;
                for (z = 0; z < xarray.length; z++) {
                    if (z < 1) {
                        z1 = xarray.length - 1;
                        z2 = 0;
                    }
                    else {
                        z1 = z - 1;
                        z2 = z;
                    }
                    y1 = yarray[z1];
                    y2 = yarray[z2];
                    if (y1 < y2) {
                        x1 = xarray[z1];
                        x2 = xarray[z2];
                    }
                    else if (y1 > y2) {
                        y2 = yarray[z1];
                        y1 = yarray[z2];
                        x2 = xarray[z1];
                        x1 = xarray[z2];
                    }
                    else continue;
                    if (((y >= y1) && (y < y2)) || ((y == maxy) && (y > y1) && (y <= y2))) sliceInts[ints++] = Math.round((y-y1) * (x2-x1) / (y2-y1) + x1);
                }
                sliceInts.sort(int_comp);
                for (z = 0; z < ints; z+=2) {
                    w = sliceInts[z+1]-sliceInts[z]+1;
                    htm += '<div style="position: absolute; left:' + sliceInts[z] + 'px; top:' + y + 'px; width:' + w + 'px; height: 1px; clip: rect(0, '+w+'px, 1px, 0); background-color:' + color + '; overflow: hidden;"><\/div>';
                }
            }
            ang_rads = (this.start_angle + (angle / 2)) * 2 * Math.PI / 360;
            this.start_angle += angle;
            var txt = "";
            var divfloat = 'left';
            if(this.use_legends == 1) {
                var label_left = centerx + label_radius;
                var label_top = legends_top;
                txt = '<div style="float: left; width: 20px; height: 12px; background-color:' + leg_color[i] + ';"></div>&nbsp;';
                legends_top += 16;
                var pc = leg_value[i] / votes_tot * 100;
                pc = pc.toFixed(1);
                var votes = leg_value[i];
                txt += leg_label[i] + " - <b>" + votes + "&nbsp;(" + pc + "%" +")</b>";
            }
            else {
                var m_top = (Math.sin(ang_rads) * label_radius) + 10;
                var m_left = (Math.cos(ang_rads) * label_radius);
                var m_leftadd = 0;
                if(m_left < 0) {
                    m_leftadd = label_width;
                    divfloat = 'right';
                }
                var label_left = centerx + m_left - m_leftadd;
                var label_top = centery - m_top;
                var pc = value[i] / votes_tot * 100;
                pc = pc.toFixed(1);
                var votes = value[i];
                txt += label[i] + " - <b>" + votes + "&nbsp;(" + pc + "%" +")</b>";
            }

            htm += '<div style="position: absolute; left: ' + label_left + 'px; top: ' + label_top + 'px;' + ' width: ' + label_width + 'px;">';
            htm += '<div style="float: ' + divfloat + '; text-align: left; font-family: verdana, helvetica, sans-serif; font-size: 10px; color: ' + this.color_style + '; font-weight: normal;">';
            htm += txt;
            htm += '<\/div><\/div>';

        }
        htm += '</div>';
        document.write(htm);
        htm = '';
    };

    function int_comp(a, b) {
        return (a < b) ? -1 : (a > b);
    }
}
