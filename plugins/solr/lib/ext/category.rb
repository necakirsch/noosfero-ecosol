require_dependency 'category'

class Category

  after_save_reindex [:articles, :profiles], with: :delayed_job

  acts_as_searchable fields: [
    # searched fields
    {name: {type: :text, boost: 2.0}},
    {path: :text}, {slug: :text},
    {abbreviation: :text}, {acronym: :text},
    # filtered fields
    :parent_id,
    # ordered/query-boosted fields
    {solr_plugin_name_sortable: :string},
  ]

  # we don't need this with NRT from solr 5
  #handle_asynchronously :solr_save
  # solr_destroy don't work with delayed_job, as AR won't be found
  #handle_asynchronously :solr_destroy

  private

  def solr_plugin_name_sortable
    name
  end

end
