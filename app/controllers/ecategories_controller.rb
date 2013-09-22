class EcategoriesController < ApplicationController
    
  def index
    @ecategories = Ecategory.find(:all)
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @ecategories.to_xml }
    end
  end

  def show
    @ecategory = Ecategory.find(params[:id])
    respond_to do |wants|
     wants.html { redirect_to ecategory_entries_url(:ecategory_id => @ecategory.id) }
     wants.xml { render :xml => @ecategory.to_xml }
    end
  end
  
  def new
    @ecategory = Ecategory.new
  end

  def create
    @ecategory = Ecategory.create(params[:ecategory])
    respond_to do |wants|
      wants.html { redirect_to admin_ecategories_url }
      wants.xml { render :xml => @ecategory.to_xml }
    end
  end

  def edit
    @ecategory = Ecategory.find(params[:id])
  end

  def update
    @ecategory = Ecategory.find(params[:id])
    @ecategory.update_attributes(params[:ecategory])
    respond_to do |wants|
      wants.html { redirect_to admin_ecategories_url }
      wants.xml { render :xml => @ecategory.to_xml }
    end
  end

  def destroy
    @category = Ecategory.find(params[:id])    
    @category.destroy
    respond_to do |wants|
      wants.html { redirect_to admin_ecategories_url }
      wants.xml { render :nothing => true }
    end
  end

  def admin
    @ecategories = Ecategory.find(:all)
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @ecategories.to_xml }
    end    
  end
end