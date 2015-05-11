function GitIndex(repo::GitRepo)
    idx_ptr_ptr = Ref{Ptr{Void}}(C_NULL)
    @check ccall((:git_repository_index, :libgit2), Cint,
                 (Ptr{Ptr{Void}}, Ptr{Void}), idx_ptr_ptr, repo.ptr)
    return GitIndex(idx_ptr_ptr[])
end

function read!(idx::GitIndex, force::Bool = false)
    @check ccall((:git_index_read, :libgit2), Cint, (Ptr{Void}, Cint), idx.ptr, Cint(force))
    return idx
end

function write!(idx::GitIndex)
    @check ccall((:git_index_write, :libgit2), Cint, (Ptr{Void},), idx.ptr)
    return idx
end

function write_tree!(idx::GitIndex)
    oid_ptr = Ref(Oid())
    @check ccall((:git_index_write_tree, :libgit2), Cint,
                 (Ptr{Oid}, Ptr{Void}), oid_ptr, idx.ptr)
    return oid_ptr[]
end

function owner(idx::GitIndex)
    repo_ptr = ccall((:git_index_owner, :libgit2), Ptr{Void},
                     (Ptr{Void},), idx.ptr)
    return GitRepo(repo_ptr)
end

function read_tree!(idx::GitIndex, tree_id::Oid)
    repo = owner(idx)
    tree = get(GitTree, repo, tree_id)
    try
        @check ccall((:git_index_read_tree, :libgit2), Cint,
                     (Ptr{Void}, Ptr{Void}), idx.ptr, tree.ptr)
    catch err
        rethrow(err)
    finally
        finalize(tree)
    end
end

function add!{T<:AbstractString}(idx::GitIndex, files::T...;
             flags::Cuint = GitConst.INDEX_ADD_DEFAULT)
    sa = StrArrayStruct(files...)
    try
        @check ccall((:git_index_add_all, :libgit2), Cint,
                     (Ptr{Void}, Ptr{StrArrayStruct}, Cuint, Ptr{Void}, Ptr{Void}),
                      idx.ptr, Ref(sa), flags, C_NULL, C_NULL)
    catch err
        rethrow(err)
    finally
        finalize(sa)
    end
end

function update!{T<:AbstractString}(idx::GitIndex, files::T...)
    sa = StrArrayStruct(files...)
    try
        @check ccall((:git_index_update_all, :libgit2), Cint,
                     (Ptr{Void}, Ptr{StrArrayStruct}, Ptr{Void}, Ptr{Void}),
                      idx.ptr, Ref(sa), C_NULL, C_NULL)
    catch err
        rethrow(err)
    finally
        finalize(sa)
    end
end

function remove!{T<:AbstractString}(idx::GitIndex, files::T...)
    sa = StrArrayStruct(files...)
    try
        @check ccall((:git_index_remove_all, :libgit2), Cint,
                     (Ptr{Void}, Ptr{StrArrayStruct}, Ptr{Void}, Ptr{Void}),
                      idx.ptr, Ref(sa), C_NULL, C_NULL)
    catch err
        rethrow(err)
    finally
        finalize(sa)
    end
end

function add!{T<:AbstractString}(repo::GitRepo, files::T...;
             flags::Cuint = GitConst.INDEX_ADD_DEFAULT)
    with(GitIndex, repo) do idx
        add!(idx, files..., flags = flags)
        write!(idx)
    end
end

function update!{T<:AbstractString}(repo::GitRepo, files::T...)
    with(GitIndex, repo) do idx
        update!(idx, files...)
        write!(idx)
    end
end

function remove!{T<:AbstractString}(repo::GitRepo, files::T...)
    with(GitIndex, repo) do idx
        remove!(idx, files...)
        write!(idx)
    end
end

function read!(repo::GitRepo, force::Bool = false)
    with(GitIndex, repo) do idx
        read!(idx, force)
    end
end