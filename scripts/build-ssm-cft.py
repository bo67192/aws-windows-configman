import os
import sys
from shutil import copyfile

def insert_powershell_script(template_file_name, powershell_file):
    """ inserts powershell script into SSM template """
    cft_file = open(template_file_name, "a", encoding="utf8")
    minified_script = ""
    with open(powershell_file, "r", encoding="utf8") as script_file:
        for script_line in script_file:
            # remove new lines so we have a single line string
            if script_line[-1] == "\n":
                script_line = script_line[:-1]
            
            # check if the line has a comment and remove
            comment_index = script_line.find("#")
            # print("Comment index " + str(comment_index))
            if comment_index > -1:
                # Only remove this comment if we are not immediately preceded by quotes
                # TODO we should update this to check if we are between quotes, not just if we are preceded by one
                # print("Comment index-1: |" + script_line[comment_index - 1] + "|")
                if comment_index == 0 or (script_line[comment_index - 1] != '"' and script_line[comment_index - 1] != "'"):
                    # print("Removing comment")
                    script_line = script_line[:comment_index]
                    # print("After removing comment: |" + script_line + "|")
            # Only append a semicolon if the line does not end in a comma
            # if script_line.find(",") > -1:
            #     print("|" + script_line + "|")
            #     print("Last char: |" + script_line[-1] + "|")
            if len(script_line) > 0 and script_line[-1] != "," and script_line[-1] != "{" and script_line[-1] != ";":
                script_line += ";"
            # append to the minified script
            # if script_line.find(",") > -1:
            #     print("|" + script_line + "|")
            # print("Before appending: |" + script_line + "|")
            minified_script += script_line
    minified_script = minified_script.replace("'", "\"")
    cft_file.write("                - '" + minified_script + "'\n")
    cft_file.close()
    return

trimmed_template_name = sys.argv[1][:-4]

built_file_name = trimmed_template_name + "-built.yml"

if not os.path.isfile(built_file_name):
    copyfile(sys.argv[1], built_file_name)

insert_powershell_script(built_file_name, sys.argv[2])