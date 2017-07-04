#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2017, Richard Levenberg <richard.levenberg@cosocloud.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

ANSIBLE_METADATA = {'metadata_version': '1.0',
                    'status': ['preview'],
                    'supported_by': 'core'}

DOCUMENTATION = r'''
---
module: win_xml
version_added: "2.0"
short_description: Add XML fragment to an XML parent
description:
    - Adds XML fragments formatted as strings to existing XML on remote servers
options:
    path:
        description:
        - The path of remote servers XML
        required: true
        aliases: [ dest, file ]
    fragment:
        description:
        - The string representation of the XML fragment to be added
        required: true
        aliases: [ xmlstring ]
    root:
        description:
        - The root of the remote server XML where the fragment will go
        required: false
        default: DocumentElement
        aliases: [ xpath ]
    backup:
        description:
        - Whether to backup the remote server's XML before applying the change (yes/no)
        required: false
        default: no
    type:
        description:
        - The type of XML you are working with
        required: yes
        default: element
        choices:
        - element
        - attribute
        - text
    attribute:
        description:
        - "The attribute name IFF type is 'attribute'"
        required: no

author: "Richard Levenberg (richard.levenberg@cosocloud.com)"
'''

EXAMPLES = r'''
# Apply our filter to Tomcat web.xml
- win_xml:
   path: C:\\apache-tomcat\webapps\myapp\WEB-INF\web.xml
   fragment: '<filter><filter-name>MyFilter</filter-name><filter-class>com.example.MyFilter</filter-class></filter>'

# Apply sslEnabledProtocols to Tomcat's server.xml
- win_xml:
   path: C:\\Tomcat\conf\server.xml
   root: '//Server/Service[@name="Catalina"]/Connector[@port="9443"]'
   attribute: 'sslEnabledProtocols'
   fragment: 'TLSv1,TLSv1.1,TLSv1.2'
   type: attribute
'''
