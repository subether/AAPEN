#
# ETHER|AAPEN|CLI - LIB|ELEMENT|CMD
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#

use strict;
use warnings;
use experimental 'signatures';
use JSON::MaybeXS;


#
# element commands
#
sub element_cmd(){

	return  {
		"element" => {
			desc => "element management",
			cmds => {
				"config" => {
					desc => "element db management",
					cmds => {
						#"meta" => {
						#	desc => "get device config metadata",
						#	proc => sub { element_meta(); }},
						"load" => {
							desc => "load element database",
							proc => sub { element_rest_config_load(@_) }},
						#"save" => {
						#	desc => "save element database",
						#	proc => sub { element_config_save(@_) }},
				}},
				"list" => {
					desc => "list elements",
					cmds => {
						"all" => {
							desc => "list all elements",
							proc => sub { element_rest_list("all", "") }},
						"cluster" => {
							desc => "list elements in cluster | <cluster>",
							proc => sub { element_rest_list("cluster", @_) }},
						"name" => {
							desc => "element name contain | <string>",
							proc => sub { element_rest_list("name", @_) }},
						"device" => {
							desc => "list device elements",
							proc => sub { element_rest_list("device", "") }},
						"service" => {
							desc => "list service elements",
							proc => sub { element_rest_list("service", "") }},
						"group" => {
							desc => "list elements in group | <group>",
							proc => sub { element_rest_list("group", @_) }},
				}},
				"info" => {
					desc => "show element json | <element>",
					proc => sub { element_rest_info( @_ ) }},
		}},
	
	};

}

1;
