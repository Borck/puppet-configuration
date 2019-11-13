# manage elements at 'This PC'
# how to hide element in 'This PC': http://www.thewindowsclub.com/remove-the-folders-from-this-pc-windows-10
# TODO move to method
# TODO partally use current user instead of local machine?

define registryx::this_pc_folder (
  Enum[present, absent] $ensure = present
) {
  $folder = downcase($name)
  $clsid = $folder ? {
    #'3d'        => '{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}',
    'desktop'   => '{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}',
    'documents' => '{f42ee2d3-909f-4907-8871-4c22fc0bf756}',
    'downloads' => '{374DE290-123F-4565-9164-39C4925E467B}',
    'music'     => '{a0c69a99-21c8-4671-8703-7934162fcf1d}',
    'pictures'  => '{0ddd015d-b06c-45d5-8c4c-f59713854639}',
    #'recycling bin' => '{645FF040-5081-101B-9F08-00AA002F954E}',
    'videos'    => '{35286a68-3c57-41a1-bbb1-0eae73d76c95}',
    default     => fail("This folder not supported: ${folder}")
  }


  $reg_folder_desc = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\${clsid}"

  registry_value { "${reg_folder_desc}\\PropertyBag\\ThisPCPolicy":
    data    => ($ensure ? { absent => 'Hide', present => 'Show'}),
  }
}

