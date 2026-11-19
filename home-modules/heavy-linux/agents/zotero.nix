# read-only access to the Zotero library for agents: the data dir is bound
# into the sandbox, and `zotero-db`, referenced by the zotero skill, queries it
{ config, pkgs, ... }:
let
  dir = "${config.home.homeDirectory}/Zotero";
in
{
  agents.sandbox.roDirs = [ dir ];

  lib.agents.zotero = pkgs.writeShellApplication {
    name = "zotero-db";
    runtimeInputs = [ pkgs.sqlite ];
    text = ''
      # Zotero holds an exclusive lock while it runs; immutable skips locking
      db="file:${dir}/zotero.sqlite?immutable=1"
      q() { sqlite3 -tabs "$db" "$1"; }
      usage() {
        echo 'usage: zotero-db tree | zotero-db ls PATH | zotero-db sql [QUERY...]' >&2
        exit 2
      }
      # collections outside the trash, as (id, path); the trash keeps them in
      # `collections`, and may leave a trashed collection's subcollections
      # unmarked
      tree="with recursive tree(id, path) as (
        select collectionID, collectionName from collections
        where parentCollectionID is null
          and collectionID not in (select collectionID from deletedCollections)
        union all
        select c.collectionID, tree.path || ' / ' || c.collectionName
        from collections c join tree on c.parentCollectionID = tree.id
        where c.collectionID not in (select collectionID from deletedCollections)
      )"
      case ''${1-} in
      tree)
        q "$tree select path from tree order by path"
        ;;
      ls)
        (($# == 2)) || usage
        c=''${2//\'/\'\'}
        q "$tree select tree.path, v.value,
          '${dir}/storage/' || ai.key || '/' || substr(a.path, 9)
        from tree
        join collectionItems ci on ci.collectionID = tree.id
        join itemData d on d.itemID = ci.itemID
        join fields f on f.fieldID = d.fieldID and f.fieldName = 'title'
        join itemDataValues v on v.valueID = d.valueID
        left join itemAttachments a on ci.itemID in (a.itemID, a.parentItemID)
          and a.contentType = 'application/pdf' and a.path like 'storage:%'
          and a.itemID not in (select itemID from deletedItems)
        left join items ai on ai.itemID = a.itemID
        where (tree.path = '$c' or substr(tree.path, 1, length('$c / ')) = '$c / ')
          and ci.itemID not in (select itemID from deletedItems)
        order by tree.path, v.value"
        ;;
      sql)
        shift
        exec sqlite3 -header -tabs "$db" "$@"
        ;;
      *) usage ;;
      esac
    '';
  };
}
